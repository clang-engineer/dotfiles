package catalog_test

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/clang-engineer/dotfiles/tools/db/internal/catalog"
)

func TestURL(t *testing.T) {
	c := catalog.Connection{Host: "::1", Port: 5432, Username: "a b", Password: "@/", Database: "demo"}
	if got := catalog.URL(c, true); got != "postgresql://a%20b:%40%2F@[::1]:5432/demo" {
		t.Fatalf("bad URL: %s", got)
	}
	if got := catalog.URL(c, false); got != "postgresql://a%20b@[::1]:5432/demo" {
		t.Fatalf("password-free URL: %s", got)
	}
}

func TestRead(t *testing.T) {
	dir := t.TempDir()
	source := []byte(`[local-db]
label = "Local"
driver = "h2"
url = "jdbc:h2:mem:test"
username = "sa"
tools = ["harlequin"]
`)
	if err := os.WriteFile(filepath.Join(dir, "local.toml"), source, 0o600); err != nil {
		t.Fatal(err)
	}
	got, err := catalog.Read(dir)
	if err != nil {
		t.Fatal(err)
	}
	if len(got) != 1 || got["local-db"].Project != "local" {
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
	dir := t.TempDir()
	if _, err := catalog.Read(dir); err == nil {
		t.Fatal("empty source accepted")
	}
	if err := os.WriteFile(filepath.Join(dir, "bad.toml"), []byte("[bad]\ndriver = 'unknown'\nlabel = 'Bad'\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := catalog.Read(dir); err == nil {
		t.Fatal("invalid driver accepted")
	}
}
