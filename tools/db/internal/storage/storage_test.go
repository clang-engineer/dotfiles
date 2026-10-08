package storage_test

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/BurntSushi/toml"
	"github.com/clang-engineer/dotfiles/tools/db/internal/storage"
)

func TestPrivateWriteDoesNotFollowFileSymlink(t *testing.T) {
	root := t.TempDir()
	source := filepath.Join(root, "original")
	link := filepath.Join(root, "link")
	if err := os.WriteFile(source, []byte("original"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink(source, link); err != nil {
		t.Fatal(err)
	}
	if err := storage.WritePrivate(link, []byte("new")); err != nil {
		t.Fatal(err)
	}
	data, _ := os.ReadFile(source)
	if string(data) != "original" {
		t.Fatal("source overwritten")
	}
	info, err := os.Stat(link)
	if err != nil || info.Mode().Perm() != 0o600 {
		t.Fatal("unsafe file permissions")
	}
	data, err = os.ReadFile(link)
	if err != nil || string(data) != "new" {
		t.Fatal("replacement missing")
	}
}

func TestEncodeTOML(t *testing.T) {
	data, err := storage.EncodeTOML(map[string]any{"nested": map[string]any{"value": "a\"b"}})
	if err != nil {
		t.Fatal(err)
	}
	var result struct{ Nested struct{ Value string } }
	if _, err := toml.Decode(string(data), &result); err != nil {
		t.Fatal(err)
	}
	if result.Nested.Value != "a\"b" {
		t.Fatal("roundtrip failed")
	}
}
