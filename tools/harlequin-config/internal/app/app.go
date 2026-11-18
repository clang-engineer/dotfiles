// Package app generates native Harlequin configurations.
package app

import (
	"fmt"
	"path/filepath"
	"sort"

	"github.com/clang-engineer/dotfiles/tools/harlequin-config/internal/catalog"
)

type configError string

func (e configError) Error() string { return string(e) }

type connection = catalog.Connection

func usage() {
	fmt.Println("usage: harlequin-config [--help]")
	fmt.Println("       harlequin-config init --source PATH")
	fmt.Println("       harlequin-config init zsh")
	fmt.Println()
	fmt.Println("Generate Harlequin profiles from the registered connection catalog.")
}

func initZsh() string {
	return `#compdef harlequin-config

_harlequin_config() {
  if [[ CURRENT -eq 3 && "${words[2]}" == "init" ]]; then
    compadd zsh --source
  elif [[ CURRENT -eq 4 && "${words[2]}" == "init" && "${words[3]}" == "--source" ]]; then
    _files -/
  elif [[ CURRENT -eq 2 ]]; then
    compadd -- init --help
  fi
}

_harlequin() {
  local context state state_descr line
  local -A opt_args
  _arguments -s -S \
    '(-P --profile)-P+[select a saved profile]:profile:->profiles' \
    '(-P --profile)--profile=[select a saved profile]:profile:->profiles' \
    '--config-path=[use a config file]:config file:_files' \
    '*:database:_files'

  if [[ $state == profiles ]]; then
    local -a profiles config_args
    if [[ -n ${opt_args[--config-path]} ]]; then
      config_args=("${(Q)opt_args[--config-path]}")
    fi
    profiles=("${(@f)$(harlequin-config --complete-harlequin-profiles "${config_args[@]}" 2>/dev/null)}") || return
    compadd -a profiles
  fi
}

compdef _harlequin_config harlequin-config
compdef _harlequin harlequin
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
	if len(args) >= 1 && len(args) <= 2 && args[0] == "--complete-harlequin-profiles" {
		path := ""
		if len(args) == 2 {
			path = args[1]
		}
		profiles, err := harlequinProfiles(path)
		if err != nil {
			return 1, err
		}
		for _, profile := range profiles {
			fmt.Println(profile)
		}
		return 0, nil
	}
	if len(args) == 3 && args[0] == "init" && args[1] == "--source" {
		if err := initializeSource(args[2]); err != nil {
			return 1, err
		}
		fmt.Println("Source saved. Run harlequin-config to generate Harlequin profiles.")
		return 0, nil
	}
	if len(args) != 0 {
		usage()
		return 2, nil
	}
	if _, err := syncCatalog(); err != nil {
		return 1, err
	}
	fmt.Printf("Generated Harlequin config: %s\n", filepath.Join(configBase(), "db", "harlequin.toml"))
	return 0, nil
}

func sortedKeys[V any](items map[string]V) []string {
	keys := make([]string, 0, len(items))
	for key := range items {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	return keys
}
