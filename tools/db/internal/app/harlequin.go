package app

import (
	"fmt"
	"github.com/clang-engineer/dotfiles/tools/db/internal/catalog"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
)

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
