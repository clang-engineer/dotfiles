package app

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"

	"github.com/clang-engineer/dotfiles/tools/db/internal/catalog"
	"github.com/clang-engineer/dotfiles/tools/db/internal/storage"
)

func launchConnection(connections map[string]connection, configDir, tool, connectionID string) (int, error) {
	c, ok := connections[connectionID]
	if !ok || !contains(c.Tools, tool) {
		return 1, launcherError(fmt.Sprintf("connection is not available for %s: %s", tool, connectionID))
	}
	switch tool {
	case "harlequin":
		return launchHarlequin(connectionID, configDir)
	case "rainfrog":
		return launchRainfrog(connectionID, c)
	default:
		return 1, launcherError("unsupported launch tool: " + tool)
	}
}

func harlequinProfile(c connection) map[string]any {
	adapter := c.Driver
	if adapter == "vertica" {
		adapter = "odbc-vertica"
	}
	profile := map[string]any{"adapter": adapter, "conn_str": []string{catalog.URL(c, true)}, "limit": 1000}
	if c.Driver == "h2" {
		profile["user"] = c.Username
		profile["password"] = c.Password
	}
	return profile
}

func harlequinKeymapArgs() ([]string, error) {
	var keymaps []string
	if configured := os.Getenv("DB_HARLEQUIN_KEYMAPS"); configured != "" {
		for _, item := range strings.Split(configured, ",") {
			keymaps = append(keymaps, strings.TrimSpace(item))
		}
	} else {
		cfg, _, err := loadDBConfig()
		if err != nil {
			return nil, err
		}
		keymaps = cfg.HarlequinKeymaps
	}
	args := []string{}
	for _, keymap := range keymaps {
		if strings.TrimSpace(keymap) != "" {
			args = append(args, "--keymap-name", strings.TrimSpace(keymap))
		}
	}
	return args, nil
}

func launchHarlequin(connectionID, configDir string) (int, error) {
	executable, err := exec.LookPath("harlequin")
	if err != nil {
		return 1, launcherError("harlequin is not installed")
	}
	config := filepath.Join(configDir, "harlequin.toml")
	if _, err := os.Stat(config); err != nil {
		return 1, launcherError(fmt.Sprintf("harlequin config not found: %s", config))
	}
	profile := strings.ReplaceAll(connectionID, "-", "_")
	keymapArgs, err := harlequinKeymapArgs()
	if err != nil {
		return 1, err
	}
	args := append([]string{executable, "--config-path", config, "-P", profile}, keymapArgs...)
	return 1, syscall.Exec(executable, args, os.Environ())
}

// Passwords remain in Rainfrog's platform keychain for both direct and launcher use.
func rainfrogProfile(c connection) map[string]any {
	return map[string]any{"connection_string": catalog.URL(c, false), "driver": c.Driver}
}

func launchRainfrog(connectionID string, c connection) (int, error) {
	executable, err := exec.LookPath("rainfrog")
	if err != nil {
		return 1, launcherError("rainfrog is not installed")
	}
	// Use an isolated selected profile; keep persistent profiles usable directly.
	dir, err := os.MkdirTemp("", "db-rainfrog-*")
	if err != nil {
		return 1, err
	}
	defer os.RemoveAll(dir)
	profile := rainfrogProfile(c)
	profile["default"] = true
	data, err := storage.EncodeTOML(map[string]any{"db": map[string]any{connectionID: profile}})
	if err != nil {
		return 1, err
	}
	if err := storage.WritePrivate(filepath.Join(dir, "rainfrog_config.toml"), data); err != nil {
		return 1, err
	}
	env := append(os.Environ(), "RAINFROG_CONFIG="+dir, "DATABASE_URL=")
	cmd := exec.Command(executable)
	cmd.Env = env
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err = cmd.Run()
	if err == nil {
		return 0, nil
	}
	if exitErr, ok := err.(*exec.ExitError); ok {
		status := exitErr.ExitCode()
		if status < 0 {
			return 128 - status, nil
		}
		return status, nil
	}
	return 1, err
}

func nvimEntry(c connection) string {
	return fmt.Sprintf("  { name = %s, url = %s },", luaString(c.Label), luaString(catalog.URL(c, true)))
}

func luaString(s string) string {
	var b strings.Builder
	b.WriteByte('"')
	for _, r := range s {
		switch r {
		case '\\', '"':
			b.WriteByte('\\')
			b.WriteRune(r)
		default:
			if r < 32 || r == 127 {
				fmt.Fprintf(&b, "\\%03d", r)
			} else {
				b.WriteRune(r)
			}
		}
	}
	b.WriteByte('"')
	return b.String()
}
