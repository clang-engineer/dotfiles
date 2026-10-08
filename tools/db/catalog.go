package main

import (
	"fmt"
	"path/filepath"
	"regexp"
	"sort"
	"strings"

	"github.com/BurntSushi/toml"
)

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

var slug = regexp.MustCompile(`^[a-z0-9][a-z0-9-]*$`)

func readCatalog(dir string) (map[string]connection, error) {
	files, err := filepath.Glob(filepath.Join(dir, "*.toml"))
	if err != nil {
		return nil, err
	}
	if len(files) == 0 {
		return nil, launcherError("no connection TOML files found; run db init --source /path/to/connections")
	}
	result := map[string]connection{}
	for _, path := range files {
		project := strings.TrimSuffix(filepath.Base(path), ".toml")
		if !slug.MatchString(project) {
			return nil, launcherError("invalid project filename: " + filepath.Base(path))
		}
		entries := map[string]connection{}
		if _, err := toml.DecodeFile(path, &entries); err != nil {
			return nil, launcherError("invalid connection TOML: " + filepath.Base(path))
		}
		for id, c := range entries {
			if _, exists := result[id]; exists {
				return nil, launcherError("duplicate connection ID: " + id)
			}
			c.Project = project
			if err := validateConnection(id, c); err != nil {
				return nil, err
			}
			result[id] = c
		}
	}
	if len(result) == 0 {
		return nil, launcherError("catalog contains no connections")
	}
	return result, nil
}

func validateConnection(id string, c connection) error {
	invalid := func(field string) error { return launcherError(fmt.Sprintf("invalid %s for connection %s", field, id)) }
	if !slug.MatchString(id) {
		return launcherError("connection IDs must be lowercase hyphenated slugs")
	}
	if c.Label == "" {
		return invalid("label")
	}
	for _, s := range []string{c.Label, c.Host, c.Database, c.Username, c.Password, c.URL} {
		if strings.ContainsFunc(s, func(r rune) bool { return r < 32 || r == 127 }) {
			return invalid("control character")
		}
	}
	allowed := map[string][]string{"postgres": {"nvim", "harlequin", "rainfrog"}, "vertica": {"nvim", "harlequin"}, "h2": {"harlequin"}}
	supported, ok := allowed[c.Driver]
	if !ok {
		return invalid("driver")
	}
	if c.Driver == "h2" {
		if !strings.HasPrefix(c.URL, "jdbc:h2:") || len(c.Params) != 0 {
			return invalid("H2 URL/params")
		}
	} else if c.Host == "" || c.Database == "" || c.Port < 1 || c.Port > 65535 {
		return invalid("host/database/port")
	}
	if len(c.Tools) == 0 {
		return invalid("tools")
	}
	seen := map[string]bool{}
	for _, tool := range c.Tools {
		if seen[tool] || !contains(supported, tool) {
			return invalid("tools")
		}
		seen[tool] = true
	}
	return nil
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
