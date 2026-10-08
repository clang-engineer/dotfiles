// Package catalog loads and validates database connection sources independently of the CLI.
package catalog

import (
	"errors"
	"fmt"
	"path/filepath"
	"regexp"
	"slices"
	"strings"

	"github.com/BurntSushi/toml"
)

// Connection is a tool-independent database target.
type Connection struct {
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

// Read validates all project TOML files before returning a catalog keyed by unique ID.
func Read(dir string) (map[string]Connection, error) {
	files, err := filepath.Glob(filepath.Join(dir, "*.toml"))
	if err != nil {
		return nil, err
	}
	if len(files) == 0 {
		return nil, errors.New("no connection TOML files found; run db init --source /path/to/connections")
	}
	result := map[string]Connection{}
	for _, path := range files {
		project := strings.TrimSuffix(filepath.Base(path), ".toml")
		if !slug.MatchString(project) {
			return nil, fmt.Errorf("invalid project filename: %s", filepath.Base(path))
		}
		entries := map[string]Connection{}
		if _, err := toml.DecodeFile(path, &entries); err != nil {
			return nil, fmt.Errorf("invalid connection TOML: %s", filepath.Base(path))
		}
		for id, c := range entries {
			if _, exists := result[id]; exists {
				return nil, fmt.Errorf("duplicate connection ID: %s", id)
			}
			c.Project = project
			if err := validateConnection(id, c); err != nil {
				return nil, err
			}
			result[id] = c
		}
	}
	if len(result) == 0 {
		return nil, errors.New("catalog contains no connections")
	}
	return result, nil
}

func validateConnection(id string, c Connection) error {
	invalid := func(field string) error { return fmt.Errorf("invalid %s for connection %s", field, id) }
	if !slug.MatchString(id) {
		return errors.New("connection IDs must be lowercase hyphenated slugs")
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
		if seen[tool] || !slices.Contains(supported, tool) {
			return invalid("tools")
		}
		seen[tool] = true
	}
	return nil
}
