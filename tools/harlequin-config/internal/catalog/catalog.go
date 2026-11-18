// Package catalog loads and validates Harlequin database connection sources.
package catalog

import (
	"errors"
	"fmt"
	"net"
	"net/url"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"

	"github.com/BurntSushi/toml"
)

// Connection is a database target for a Harlequin profile.
type Connection struct {
	Driver   string            `toml:"driver"`
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
		return nil, errors.New("no connection TOML files found; run harlequin-config init --source /path/to/connections")
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
	for _, s := range []string{c.Host, c.Database, c.Username, c.Password, c.URL} {
		if strings.ContainsFunc(s, func(r rune) bool { return r < 32 || r == 127 }) {
			return invalid("control character")
		}
	}
	switch c.Driver {
	case "postgres", "vertica", "h2":
	default:
		return invalid("driver")
	}
	if c.Driver == "h2" {
		if !strings.HasPrefix(c.URL, "jdbc:h2:") || len(c.Params) != 0 {
			return invalid("H2 URL/params")
		}
	} else if c.Host == "" || c.Database == "" || c.Port < 1 || c.Port > 65535 {
		return invalid("host/database/port")
	}
	return nil
}

// URL encodes a target using the database driver's connection-string syntax.
func URL(c Connection) string {
	if c.Driver == "h2" {
		return c.URL
	}
	if c.Driver == "vertica" {
		escape := func(s string) string { return "{" + strings.ReplaceAll(s, "}", "}}") + "}" }
		return fmt.Sprintf("DRIVER={Vertica};SERVER=%s;PORT=%d;DATABASE=%s;UID=%s;PWD=%s", escape(c.Host), c.Port, escape(c.Database), escape(c.Username), escape(c.Password))
	}
	u := url.URL{Scheme: "postgresql", Host: net.JoinHostPort(c.Host, strconv.Itoa(c.Port)), Path: "/" + c.Database}
	u.User = url.User(c.Username)
	if c.Password != "" {
		u.User = url.UserPassword(c.Username, c.Password)
	}
	q := url.Values{}
	for k, v := range c.Params {
		q.Set(k, v)
	}
	u.RawQuery = q.Encode()
	return u.String()
}
