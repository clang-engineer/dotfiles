package app

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/BurntSushi/toml"
	"github.com/clang-engineer/dotfiles/tools/db/internal/catalog"
	"github.com/clang-engineer/dotfiles/tools/db/internal/storage"
)

type stringList []string

func (s *stringList) UnmarshalTOML(value any) error {
	switch typed := value.(type) {
	case string:
		*s = []string{typed}
	case []any:
		items := make([]string, 0, len(typed))
		for _, item := range typed {
			text, ok := item.(string)
			if !ok {
				return launcherError("harlequin_keymaps must be a string or list of strings")
			}
			items = append(items, text)
		}
		*s = items
	default:
		return launcherError("harlequin_keymaps must be a string or list of strings")
	}
	return nil
}

type dbConfig struct {
	ConnectionsDir   string     `toml:"connections_dir"`
	Tool             string     `toml:"tool"`
	Connection       string     `toml:"connection"`
	HarlequinKeymaps stringList `toml:"harlequin_keymaps"`
}

func configBase() string {
	if home := os.Getenv("XDG_CONFIG_HOME"); home != "" {
		return expandHome(home)
	}
	home, _ := os.UserHomeDir()
	return filepath.Join(home, ".config")
}

func expandHome(path string) string {
	if path == "~" || strings.HasPrefix(path, "~/") {
		home, _ := os.UserHomeDir()
		if path == "~" {
			return home
		}
		return filepath.Join(home, strings.TrimPrefix(path, "~/"))
	}
	return path
}

func defaultConfigPath() string { return filepath.Join(configBase(), "db", "config.toml") }

func loadDBConfig() (dbConfig, map[string]any, error) {
	path := defaultConfigPath()
	var cfg dbConfig
	raw := map[string]any{}
	data, err := os.ReadFile(path)
	if errors.Is(err, os.ErrNotExist) {
		return cfg, raw, nil
	}
	if err != nil {
		return cfg, raw, err
	}
	if _, err := toml.Decode(string(data), &cfg); err != nil {
		return cfg, raw, launcherError(fmt.Sprintf("invalid default config: %v", err))
	}
	if _, err := toml.Decode(string(data), &raw); err != nil {
		return cfg, raw, launcherError(fmt.Sprintf("invalid default config: %v", err))
	}
	return cfg, raw, nil
}

func sourcePath() (string, error) {
	cfg, _, err := loadDBConfig()
	if err != nil {
		return "", err
	}
	if cfg.ConnectionsDir != "" {
		return expandHome(cfg.ConnectionsDir), nil
	}
	return filepath.Join(configBase(), "db", "connections"), nil
}

func initializeSource(path string) error {
	absolute, err := filepath.Abs(expandHome(path))
	if err != nil {
		return err
	}
	if _, err := catalog.Read(absolute); err != nil {
		return err
	}
	_, raw, err := loadDBConfig()
	if err != nil {
		return err
	}
	raw["connections_dir"] = absolute
	data, err := storage.EncodeTOML(raw)
	if err != nil {
		return err
	}
	return storage.WritePrivate(defaultConfigPath(), data)
}

func interactiveTool() (string, error) {
	cfg, _, err := loadDBConfig()
	if err != nil {
		return "", err
	}
	if cfg.Tool == "" {
		return "harlequin", nil
	}
	if !contains(launchTools(), cfg.Tool) {
		return "", launcherError(fmt.Sprintf("invalid interactive tool in default config: %s", defaultConfigPath()))
	}
	return cfg.Tool, nil
}

func loadDefault(connections map[string]connection) (string, string, bool, error) {
	cfg, _, err := loadDBConfig()
	if err != nil {
		return "", "", false, err
	}
	if cfg.Tool == "" && cfg.Connection == "" {
		return "", "", false, nil
	}
	if !contains(launchTools(), cfg.Tool) || cfg.Connection == "" {
		return "", "", false, launcherError(fmt.Sprintf("invalid default config: %s", defaultConfigPath()))
	}
	conn, ok := connections[cfg.Connection]
	if !ok {
		return "", "", false, launcherError(fmt.Sprintf("default connection not found: %s", cfg.Connection))
	}
	if !contains(conn.Tools, cfg.Tool) {
		return "", "", false, launcherError(fmt.Sprintf("default connection is not available for %s: %s", cfg.Tool, cfg.Connection))
	}
	return cfg.Tool, cfg.Connection, true, nil
}

func saveDefault(tool, connectionID string) (string, error) {
	path := defaultConfigPath()
	_, raw, err := loadDBConfig()
	if err != nil {
		return "", err
	}
	raw["tool"] = tool
	raw["connection"] = connectionID
	data, err := storage.EncodeTOML(raw)
	if err != nil {
		return "", err
	}
	return path, storage.WritePrivate(path, data)
}

// harlequinProfiles reads names only, without syncing or loading the source catalog.
func harlequinProfiles(configPath string) ([]string, error) {
	if configPath == "" {
		configPath = os.Getenv("HARLEQUIN_CONFIG_PATH")
	}
	var paths []string
	if configPath != "" {
		configPath = expandHome(configPath)
		paths = append(paths, configPath)
	}
	cwd, err := os.Getwd()
	if err != nil {
		return nil, err
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return nil, err
	}
	configHome, err := os.UserConfigDir()
	if err != nil {
		return nil, err
	}
	for _, directory := range []struct {
		path  string
		names []string
	}{
		{cwd, []string{"harlequin.toml", ".harlequin.toml", "pyproject.toml"}},
		{filepath.Join(configHome, "harlequin"), []string{"harlequin.toml", ".harlequin.toml", "config.toml"}},
		{home, []string{"harlequin.toml", ".harlequin.toml", "pyproject.toml"}},
	} {
		for _, name := range directory.names {
			paths = append(paths, filepath.Join(directory.path, name))
		}
	}
	type profileNames struct {
		Profiles map[string]struct{}
	}
	profiles := map[string]struct{}{"None": {}}
	for _, path := range paths {
		var config struct {
			profileNames
			Tool struct {
				Harlequin profileNames
			}
		}
		if _, err := toml.DecodeFile(path, &config); err != nil {
			if errors.Is(err, os.ErrNotExist) && path != configPath {
				continue
			}
			return nil, fmt.Errorf("reading Harlequin config %s: %w", path, err)
		}
		names := config.Profiles
		if strings.TrimSuffix(filepath.Base(path), filepath.Ext(path)) == "pyproject" {
			names = config.Tool.Harlequin.Profiles
		}
		for name := range names {
			profiles[name] = struct{}{}
		}
	}
	return sortedKeys(profiles), nil
}
