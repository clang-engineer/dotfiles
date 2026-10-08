// Package app coordinates CLI commands, selection, configuration, and client execution.
package app

import (
	"fmt"
	"path/filepath"
)

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
