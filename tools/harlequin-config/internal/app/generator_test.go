package app

import (
	"os"
	"path/filepath"
	"reflect"
	"testing"

	"github.com/BurntSushi/toml"
	"github.com/clang-engineer/dotfiles/tools/harlequin-config/internal/storage"
)

func TestGenerateWithoutLaunchingOrSavingChoice(t *testing.T) {
	dir := setupCatalog(t)
	if err := initializeSource(dir); err != nil {
		t.Fatal(err)
	}
	// Obsolete settings are ignored, even when their types were never valid.
	config := "tool = 42\nconnection = ['retired']\nharlequin_keymaps = 'vscode'\nconnections_dir = " + "'" + filepath.ToSlash(dir) + "'\n"
	if err := storage.WritePrivate(defaultConfigPath(), []byte(config)); err != nil {
		t.Fatal(err)
	}
	t.Setenv("PATH", t.TempDir())
	code, err := Run(nil)
	if code != 0 || err != nil {
		t.Fatalf("generate: %d %v", code, err)
	}
	after, err := os.ReadFile(defaultConfigPath())
	if err != nil || string(after) != config {
		t.Fatalf("generation persisted a choice: %v", err)
	}
}

func TestGeneratedKeymaps(t *testing.T) {
	for _, tc := range []struct {
		name    string
		setting string
		want    []string
	}{
		{"unset", "", nil},
		{"single", "harlequin_keymaps = 'vscode'\n", []string{"vscode"}},
		{"multiple", "harlequin_keymaps = [' vscode ', '', 'vim']\n", []string{"vscode", "vim"}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			setupCatalog(t)
			t.Setenv("DB_HARLEQUIN_KEYMAPS", "obsolete-override")
			if err := storage.WritePrivate(defaultConfigPath(), []byte(tc.setting)); err != nil {
				t.Fatal(err)
			}
			output, err := renderCatalog(map[string]connection{"local-db": {Driver: "postgres"}})
			if err != nil {
				t.Fatal(err)
			}
			var config struct {
				Profiles map[string]struct {
					Keymaps []string `toml:"keymap_name"`
				}
			}
			if _, err := toml.Decode(string(output), &config); err != nil {
				t.Fatal(err)
			}
			if got := config.Profiles["local_db"].Keymaps; !reflect.DeepEqual(got, tc.want) {
				t.Fatalf("keymaps: got %q, want %q", got, tc.want)
			}
		})
	}
}

func TestInvalidKeymapsDoNotChangeOutputs(t *testing.T) {
	dir := setupCatalog(t)
	if err := initializeSource(dir); err != nil {
		t.Fatal(err)
	}
	if _, err := syncCatalog(); err != nil {
		t.Fatal(err)
	}
	path := filepath.Join(configBase(), "db", "harlequin.toml")
	before, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	for _, setting := range []string{"42", "['vscode', 42]"} {
		if err := storage.WritePrivate(defaultConfigPath(), []byte("harlequin_keymaps = "+setting)); err != nil {
			t.Fatal(err)
		}
		if _, err := syncCatalog(); err == nil {
			t.Fatal("invalid keymaps accepted")
		}
		after, err := os.ReadFile(path)
		if err != nil || string(after) != string(before) {
			t.Fatalf("invalid config changed output: %v", err)
		}
	}
}
