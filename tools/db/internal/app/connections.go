package app

import (
	"sort"

	"github.com/clang-engineer/dotfiles/tools/db/internal/catalog"
)

// connection is the shared catalog model, not a separate application DTO.
type connection = catalog.Connection

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
