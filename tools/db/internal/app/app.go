// Package app coordinates CLI commands, selection, configuration, and client execution.
package app

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"

	"github.com/clang-engineer/dotfiles/tools/db/internal/catalog"
)

type launcherError string

func (e launcherError) Error() string { return string(e) }

// connection is the shared catalog model, not a separate application DTO.
type connection = catalog.Connection

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

// Run executes a CLI command and returns its exit status without exiting the process.
func Run(args []string) (int, error) {
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

	var connections map[string]connection
	var err error
	if preview {
		connections, err = loadConnections()
	} else {
		connections, err = syncCatalog()
	}
	if err != nil {
		return 1, err
	}

	configDir := filepath.Join(configBase(), "db")
	if len(args) == 1 && args[0] == "sync" {
		fmt.Printf("Generated tool configs: %s\n", configDir)
		return 0, nil
	}
	if len(args) == 0 {
		tool, connectionID, ok, err := loadDefault(connections)
		if err != nil {
			return 1, err
		}
		if !ok {
			return runInteractive(connections, configDir)
		}
		return launchConnection(connections, configDir, tool, connectionID)
	}
	if len(args) == 1 && args[0] == "--select" {
		return runInteractive(connections, configDir)
	}
	if len(args) == 1 && args[0] == "--set-default" {
		tool, connectionID, ok, err := selectConnection(connections)
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
		previewTool(connections, args[1])
		return 0, nil
	}
	if len(args) == 3 && args[0] == "--preview-project" {
		previewProject(connections, args[1], args[2])
		return 0, nil
	}
	if len(args) == 3 && args[0] == "--preview-connection" {
		return 0, previewConnection(connections, args[1], args[2])
	}
	usage()
	return 2, nil
}

func launchTools() []string { return []string{"harlequin", "rainfrog"} }

func runInteractive(connections map[string]connection, configDir string) (int, error) {
	tool, connectionID, ok, err := selectConnection(connections)
	if err != nil {
		return 1, err
	}
	if !ok {
		return 130, nil
	}
	return launchConnection(connections, configDir, tool, connectionID)
}

func availableConnections(connections map[string]connection, tool, project string) map[string]connection {
	entries := map[string]connection{}
	for id, conn := range connections {
		if contains(conn.Tools, tool) && (project == "" || conn.Project == project) {
			entries[id] = conn
		}
	}
	return entries
}

func contains(items []string, value string) bool {
	for _, item := range items {
		if item == value {
			return true
		}
	}
	return false
}

func sortedKeys[V any](items map[string]V) []string {
	keys := make([]string, 0, len(items))
	for key := range items {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	return keys
}

func previewTool(connections map[string]connection, tool string) {
	entries := availableConnections(connections, tool, "")
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

func previewProject(connections map[string]connection, tool, project string) {
	entries := availableConnections(connections, tool, project)
	fmt.Printf("Project: %s\n", project)
	fmt.Printf("Tool: %s\n\n", tool)
	fmt.Println("Connections:")
	for _, id := range sortedKeys(entries) {
		fmt.Printf("  %s  %s\n", id, entries[id].Label)
	}
}

func previewConnection(connections map[string]connection, tool, connectionID string) error {
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

func shellQuote(value string) string { return "'" + strings.ReplaceAll(value, "'", "'\\''") + "'" }

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

func selectConnection(connections map[string]connection) (string, string, bool, error) {
	for {
		tool, ok, err := pick(launchTools(), "tool", []string{"--preview-tool"}, false, "exit")
		if err != nil || !ok {
			return "", "", false, err
		}
		for {
			entries := availableConnections(connections, tool, "")
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
				projectEntries := availableConnections(connections, tool, project)
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
