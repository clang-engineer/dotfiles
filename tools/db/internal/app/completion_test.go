package app

import (
	"errors"
	"os"
	"path/filepath"
	"slices"
	"testing"
)

func TestHarlequinProfilesDiscovery(t *testing.T) {
	home := t.TempDir()
	t.Setenv("HOME", home)
	t.Setenv("XDG_CONFIG_HOME", filepath.Join(home, ".config"))
	t.Chdir(t.TempDir())
	configHome, err := os.UserConfigDir()
	if err != nil {
		t.Fatal(err)
	}
	write := func(path, content string) {
		t.Helper()
		if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(path, []byte(content), 0o600); err != nil {
			t.Fatal(err)
		}
	}
	write(filepath.Join(home, ".harlequin.toml"), "[profiles.home]\npassword = 'private-value'\n[profiles.shared]\n")
	write(filepath.Join(configHome, "harlequin", "config.toml"), "[profiles.user_config]\n[profiles.shared]\n")
	write("pyproject.toml", "[profiles.not_harlequin]\n[tool.harlequin.profiles.project]\n")
	envPath := filepath.Join(t.TempDir(), "env.toml")
	write(envPath, "[profiles.environment]\n")
	explicitPath := filepath.Join(t.TempDir(), "explicit config.toml")
	write(explicitPath, "[profiles.'explicit profile']\n[profiles.shared]\n")
	t.Setenv("HARLEQUIN_CONFIG_PATH", envPath)

	for _, tc := range []struct {
		name string
		path string
		want []string
	}{
		{"environment", "", []string{"None", "environment", "home", "project", "shared", "user_config"}},
		{"explicit_overrides_environment", explicitPath, []string{"None", "explicit profile", "home", "project", "shared", "user_config"}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			got, err := harlequinProfiles(tc.path)
			if err != nil {
				t.Fatal(err)
			}
			if !slices.Equal(got, tc.want) {
				t.Fatalf("profiles: got %q, want %q", got, tc.want)
			}
		})
	}
}

func TestHarlequinProfilesInvalidConfig(t *testing.T) {
	home := t.TempDir()
	t.Setenv("HOME", home)
	t.Setenv("XDG_CONFIG_HOME", filepath.Join(home, ".config"))
	t.Setenv("HARLEQUIN_CONFIG_PATH", "")
	t.Chdir(t.TempDir())

	if _, err := harlequinProfiles(filepath.Join(home, "missing.toml")); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("missing explicit config: %v", err)
	}
	t.Setenv("HARLEQUIN_CONFIG_PATH", filepath.Join(home, "missing.toml"))
	if _, err := harlequinProfiles(""); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("missing environment config: %v", err)
	}
	t.Setenv("HARLEQUIN_CONFIG_PATH", "")
	if err := os.WriteFile(".harlequin.toml", []byte("[profiles.broken"), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := harlequinProfiles(""); err == nil {
		t.Fatal("malformed native config accepted")
	}
}
