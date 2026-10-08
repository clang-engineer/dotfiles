package main

import (
	"os"
	"os/exec"
	"path/filepath"
)

// Passwords remain in Rainfrog's platform keychain for both direct and launcher use.
func rainfrogProfile(c connection) map[string]any {
	return map[string]any{"connection_string": connectionURL(c, false), "driver": c.Driver}
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
	data, err := encodeTOML(map[string]any{"db": map[string]any{connectionID: profile}})
	if err != nil {
		return 1, err
	}
	if err := writePrivate(filepath.Join(dir, "rainfrog_config.toml"), data); err != nil {
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
