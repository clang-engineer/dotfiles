package catalog_test

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/clang-engineer/dotfiles/tools/harlequin-config/internal/catalog"
)

func TestURL(t *testing.T) {
	c := catalog.Connection{Host: "::1", Port: 5432, Username: "a b", Password: "@/", Database: "demo"}
	if got := catalog.URL(c); got != "postgresql://a%20b:%40%2F@[::1]:5432/demo" {
		t.Fatal("incorrect PostgreSQL URL escaping")
	}
	c.Password = ""
	if got := catalog.URL(c); got != "postgresql://a%20b@[::1]:5432/demo" {
		t.Fatal("incorrect password-free PostgreSQL URL")
	}
}

func TestReadMinimalConnection(t *testing.T) {
	dir := t.TempDir()
	source := []byte(`[local-db]
driver = "h2"
url = "jdbc:h2:mem:test"
`)
	if err := os.WriteFile(filepath.Join(dir, "local.toml"), source, 0o600); err != nil {
		t.Fatal(err)
	}
	got, err := catalog.Read(dir)
	if err != nil {
		t.Fatal(err)
	}
	if len(got) != 1 || got["local-db"].Driver != "h2" || got["local-db"].URL != "jdbc:h2:mem:test" {
		t.Fatal("incorrect catalog")
	}
	if err := os.WriteFile(filepath.Join(dir, "duplicate.toml"), source, 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := catalog.Read(dir); err == nil {
		t.Fatal("duplicate accepted")
	}
}

func TestReadRejectsEmptyAndInvalidSources(t *testing.T) {
	if _, err := catalog.Read(t.TempDir()); err == nil {
		t.Fatal("empty source accepted")
	}
	for _, tc := range []struct {
		name     string
		filename string
		source   string
	}{
		{"empty catalog", "local.toml", ""},
		{"malformed TOML", "local.toml", "[local-db"},
		{"invalid project", "Invalid.toml", "[local-db]\ndriver = 'h2'\nurl = 'jdbc:h2:mem:test'\n"},
		{"invalid ID", "local.toml", "[invalid_id]\ndriver = 'h2'\nurl = 'jdbc:h2:mem:test'\n"},
		{"unknown driver", "local.toml", "[local-db]\ndriver = 'unknown'\n"},
		{"missing driver", "local.toml", "[local-db]\nurl = 'jdbc:h2:mem:test'\n"},
		{"invalid H2 URL", "local.toml", "[local-db]\ndriver = 'h2'\nurl = 'jdbc:other:mem:test'\n"},
		{"H2 params", "local.toml", "[local-db]\ndriver = 'h2'\nurl = 'jdbc:h2:mem:test'\nparams = { ssl = 'true' }\n"},
		{"missing host", "local.toml", "[local-db]\ndriver = 'postgres'\ndatabase = 'demo'\nport = 5432\n"},
		{"missing database", "local.toml", "[local-db]\ndriver = 'vertica'\nhost = 'localhost'\nport = 5433\n"},
		{"missing port", "local.toml", "[local-db]\ndriver = 'postgres'\nhost = 'localhost'\ndatabase = 'demo'\n"},
		{"invalid port", "local.toml", "[local-db]\ndriver = 'postgres'\nhost = 'localhost'\ndatabase = 'demo'\nport = 65536\n"},
		{"control character", "local.toml", "[local-db]\ndriver = 'h2'\nurl = 'jdbc:h2:mem:test'\npassword = \"bad\\nvalue\"\n"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			dir := t.TempDir()
			if err := os.WriteFile(filepath.Join(dir, tc.filename), []byte(tc.source), 0o600); err != nil {
				t.Fatal(err)
			}
			if _, err := catalog.Read(dir); err == nil {
				t.Fatal("invalid source accepted")
			}
		})
	}
}
