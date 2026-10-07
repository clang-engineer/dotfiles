package main

import (
	"bytes"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"syscall"

	"github.com/BurntSushi/toml"
)

var tools = []string{"harlequin", "rainfrog"}

var connections map[string]connection

type launcherError string

func (e launcherError) Error() string { return string(e) }

type connection struct {
	Project  string            `toml:"project"`
	Driver   string            `toml:"driver"`
	Label    string            `toml:"label"`
	Tools    []string          `toml:"tools"`
	URL      string            `toml:"url"`
	Host     string            `toml:"host"`
	Port     int               `toml:"port"`
	Database string            `toml:"database"`
	Username string            `toml:"username"`
	Password string            `toml:"password"`
	Params   map[string]string `toml:"params"`
}

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

func usage() {
	fmt.Println("usage: db [--select | --set-default | sync | init --source DIR | init zsh | --help]")
	fmt.Println()
	fmt.Println("Launch the default database or select one interactively.")
	fmt.Println()
	fmt.Println("  --select       ignore the default and select a database")
	fmt.Println("  --set-default  select and save the default database")
	fmt.Println("  init --source DIR  save the connection source directory")
	fmt.Println("  sync           generate persistent tool configs from source TOML")
	fmt.Println("  init zsh       output zsh completion script")
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

func loadConnections() (map[string]connection, error) {
	path, err := sourcePath()
	if err != nil {
		return nil, err
	}
	return readCatalog(path)
}

func contains(items []string, value string) bool {
	for _, item := range items {
		if item == value {
			return true
		}
	}
	return false
}

func loadDefault() (string, string, bool, error) {
	cfg, _, err := loadDBConfig()
	if err != nil {
		return "", "", false, err
	}
	if cfg.Tool == "" && cfg.Connection == "" {
		return "", "", false, nil
	}
	if !contains(tools, cfg.Tool) || cfg.Connection == "" {
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
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return "", err
	}
	_, raw, err := loadDBConfig()
	if err != nil {
		return "", err
	}
	raw["tool"] = tool
	raw["connection"] = connectionID
	var buf bytes.Buffer
	if err := toml.NewEncoder(&buf).Encode(raw); err != nil {
		return "", err
	}
	tmp, err := os.CreateTemp(filepath.Dir(path), ".config.*")
	if err != nil {
		return "", err
	}
	tmpPath := tmp.Name()
	defer os.Remove(tmpPath)
	if _, err := tmp.Write(buf.Bytes()); err != nil {
		tmp.Close()
		return "", err
	}
	if err := tmp.Close(); err != nil {
		return "", err
	}
	if err := os.Chmod(tmpPath, 0o600); err != nil {
		return "", err
	}
	return path, os.Rename(tmpPath, path)
}

func availableConnections(tool, project string) map[string]connection {
	entries := map[string]connection{}
	for id, conn := range connections {
		if contains(conn.Tools, tool) && (project == "" || conn.Project == project) {
			entries[id] = conn
		}
	}
	return entries
}

func sortedKeys[V any](items map[string]V) []string {
	keys := make([]string, 0, len(items))
	for key := range items {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	return keys
}

func previewTool(tool string) {
	entries := availableConnections(tool, "")
	projects := map[string]bool{}
	drivers := map[string]bool{}
	for _, entry := range entries {
		projects[entry.Project] = true
		drivers[entry.Driver] = true
	}
	fmt.Printf("Tool: %s\n", tool)
	fmt.Printf("Projects: %d\n", len(projects))
	fmt.Printf("Connections: %d\n", len(entries))
	fmt.Printf("Drivers: %s\n", strings.Join(sortedKeys(drivers), ", "))
}

func previewProject(tool, project string) {
	entries := availableConnections(tool, project)
	fmt.Printf("Project: %s\n", project)
	fmt.Printf("Tool: %s\n\n", tool)
	fmt.Println("Connections:")
	for _, id := range sortedKeys(entries) {
		fmt.Printf("  %s  %s\n", id, entries[id].Label)
	}
}

func previewConnection(tool, connectionID string) error {
	conn, ok := connections[connectionID]
	if !ok || !contains(conn.Tools, tool) {
		return launcherError(fmt.Sprintf("connection is not available for %s: %s", tool, connectionID))
	}
	fmt.Printf("ID: %s\n", connectionID)
	fmt.Printf("Label: %s\n", conn.Label)
	fmt.Printf("Driver: %s\n", conn.Driver)
	if conn.Driver == "h2" {
		fmt.Printf("URL: %s\n", conn.URL)
	} else {
		fmt.Printf("Host: %s:%d\n", conn.Host, conn.Port)
		fmt.Printf("Database: %s\n", conn.Database)
	}
	fmt.Printf("Username: %s\n", conn.Username)
	return nil
}

func shellQuote(value string) string {
	return "'" + strings.ReplaceAll(value, "'", "'\\''") + "'"
}

func pick(items []string, prompt string, previewArgs []string, dbRows bool, escapeAction string) (string, bool, error) {
	if _, err := exec.LookPath("fzf"); err != nil {
		return "", false, launcherError("fzf is required for interactive selection")
	}
	script, err := os.Executable()
	if err != nil {
		return "", false, err
	}
	previewParts := []string{shellQuote(script)}
	for _, arg := range previewArgs {
		previewParts = append(previewParts, shellQuote(arg))
	}
	preview := strings.Join(previewParts, " ")
	if dbRows {
		preview += " {1}"
	} else {
		preview += " {}"
	}
	args := []string{"--height=40%", "--layout=reverse", "--border", "--prompt=" + prompt + "> ", "--preview=" + preview, "--preview-window=right:45%", "--header=Esc: " + escapeAction}
	if dbRows {
		args = append(args, "--delimiter=\t", "--with-nth=1,2")
	}
	cmd := exec.Command("fzf", args...)
	cmd.Stdin = strings.NewReader(strings.Join(items, "\n") + "\n")
	var out bytes.Buffer
	cmd.Stdout = &out
	err = cmd.Run()
	if exitErr, ok := err.(*exec.ExitError); ok && exitErr.ExitCode() == 130 {
		return "", false, nil
	}
	if err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok {
			return "", false, launcherError(fmt.Sprintf("fzf failed with exit status %d", exitErr.ExitCode()))
		}
		return "", false, err
	}
	selection := strings.TrimSuffix(out.String(), "\n")
	if selection == "" {
		return "", false, launcherError("fzf returned an empty selection")
	}
	if dbRows {
		selection = strings.SplitN(selection, "\t", 2)[0]
	}
	return selection, true, nil
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

func launchRainfrog(connectionID, configDir string) (int, error) {
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
	c := connections[connectionID]
	// Passwords remain in Rainfrog's platform keychain, as in persistent config.
	data, err := encodeTOML(map[string]any{"db": map[string]any{connectionID: map[string]any{
		"connection_string": connectionURL(c, false), "driver": c.Driver, "default": true,
	}}})
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

func selectConnection() (string, string, bool, error) {
	for {
		tool, ok, err := pick(tools, "tool", []string{"--preview-tool"}, false, "exit")
		if err != nil || !ok {
			return "", "", false, err
		}
		for {
			entries := availableConnections(tool, "")
			projectsSet := map[string]bool{}
			for _, entry := range entries {
				projectsSet[entry.Project] = true
			}
			project, ok, err := pick(sortedKeys(projectsSet), "project", []string{"--preview-project", tool}, false, "back")
			if err != nil {
				return "", "", false, err
			}
			if !ok {
				break
			}
			for {
				projectEntries := availableConnections(tool, project)
				rows := []string{}
				for _, id := range sortedKeys(projectEntries) {
					rows = append(rows, id+"\t"+projectEntries[id].Label)
				}
				connectionID, ok, err := pick(rows, "database", []string{"--preview-connection", tool}, true, "back")
				if err != nil {
					return "", "", false, err
				}
				if !ok {
					break
				}
				return tool, connectionID, true, nil
			}
		}
	}
}

func launchConnection(configDir, tool, connectionID string) (int, error) {
	if tool == "harlequin" {
		return launchHarlequin(connectionID, configDir)
	}
	return launchRainfrog(connectionID, configDir)
}

func runInteractive(configDir string) (int, error) {
	tool, connectionID, ok, err := selectConnection()
	if err != nil {
		return 1, err
	}
	if !ok {
		return 130, nil
	}
	return launchConnection(configDir, tool, connectionID)
}

func initZsh() string {
	return `#compdef db

_db() {
  if [[ CURRENT -eq 3 && "${words[2]}" == "init" ]]; then
    compadd zsh --source
  else
    compadd -- --select --set-default sync init
  fi
}

compdef _db db
`
}

func mainResult(args []string) (int, error) {
	if len(args) == 1 && (args[0] == "-h" || args[0] == "--help") {
		usage()
		return 0, nil
	}
	if len(args) == 2 && args[0] == "init" && args[1] == "zsh" {
		fmt.Print(initZsh())
		return 0, nil
	}
	if len(args) == 3 && args[0] == "init" && args[1] == "--source" {
		if err := initializeSource(args[2]); err != nil {
			return 1, err
		}
		fmt.Println("Source saved. Run db sync or db to generate tool configs.")
		return 0, nil
	}
	preview := len(args) == 2 && args[0] == "--preview-tool" || len(args) == 3 && (args[0] == "--preview-project" || args[0] == "--preview-connection")
	valid := len(args) == 0 || len(args) == 1 && contains([]string{"sync", "--select", "--set-default"}, args[0]) || preview
	if !valid {
		usage()
		return 2, nil
	}
	var loaded map[string]connection
	var err error
	if preview {
		loaded, err = loadConnections()
	} else {
		loaded, err = syncCatalog()
	}
	if err != nil {
		return 1, err
	}
	connections = loaded
	configDir := filepath.Join(configBase(), "db")
	if len(args) == 1 && args[0] == "sync" {
		fmt.Printf("Generated tool configs: %s\n", configDir)
		return 0, nil
	}

	if len(args) == 0 {
		tool, connectionID, ok, err := loadDefault()
		if err != nil {
			return 1, err
		}
		if !ok {
			return runInteractive(configDir)
		}
		return launchConnection(configDir, tool, connectionID)
	}
	if len(args) == 1 && args[0] == "--select" {
		return runInteractive(configDir)
	}
	if len(args) == 1 && args[0] == "--set-default" {
		tool, connectionID, ok, err := selectConnection()
		if err != nil {
			return 1, err
		}
		if !ok {
			return 130, nil
		}
		path, err := saveDefault(tool, connectionID)
		if err != nil {
			return 1, err
		}
		fmt.Printf("Default database saved: %s / %s\n", tool, connectionID)
		fmt.Printf("Config: %s\n", path)
		return 0, nil
	}
	if len(args) == 2 && args[0] == "--preview-tool" {
		previewTool(args[1])
		return 0, nil
	}
	if len(args) == 3 && args[0] == "--preview-project" {
		previewProject(args[1], args[2])
		return 0, nil
	}
	if len(args) == 3 && args[0] == "--preview-connection" {
		return 0, previewConnection(args[1], args[2])
	}
	usage()
	return 2, nil
}

func main() {
	code, err := mainResult(os.Args[1:])
	if err != nil {
		fmt.Fprintf(os.Stderr, "db: %v\n", err)
		os.Exit(1)
	}
	os.Exit(code)
}
