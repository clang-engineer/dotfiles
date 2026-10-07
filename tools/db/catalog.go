package main

import (
	"bytes"
	"fmt"
	"net"
	"net/url"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"

	"github.com/BurntSushi/toml"
)

var slug = regexp.MustCompile(`^[a-z0-9][a-z0-9-]*$`)

func sourcePath() (string, error) {
	cfg, _, err := loadDBConfig()
	if err != nil {
		return "", err
	}
	if cfg.ConnectionsDir != "" {
		return expandHome(cfg.ConnectionsDir), nil
	}
	return filepath.Join(configBase(), "db", "connections"), nil
}

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

func encodeTOML(v any) ([]byte, error) {
	var b bytes.Buffer
	err := toml.NewEncoder(&b).Encode(v)
	return b.Bytes(), err
}

// Atomic replacement never follows an existing file symlink into a source repository.
func writePrivate(path string, data []byte) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		return err
	}
	f, err := os.CreateTemp(filepath.Dir(path), ".db-*")
	if err != nil {
		return err
	}
	defer os.Remove(f.Name())
	if _, err := f.Write(data); err != nil {
		f.Close()
		return err
	}
	if err := f.Close(); err != nil {
		return err
	}
	return os.Rename(f.Name(), path)
}

func initializeSource(path string) error {
	absolute, err := filepath.Abs(expandHome(path))
	if err != nil {
		return err
	}
	if _, err := readCatalog(absolute); err != nil {
		return err
	}
	_, raw, err := loadDBConfig()
	if err != nil {
		return err
	}
	raw["connections_dir"] = absolute
	data, err := encodeTOML(raw)
	if err != nil {
		return err
	}
	return writePrivate(defaultConfigPath(), data)
}

func connectionURL(c connection, password bool) string {
	if c.Driver == "h2" {
		return c.URL
	}
	if c.Driver == "vertica" {
		escape := func(s string) string { return "{" + strings.ReplaceAll(s, "}", "}}") + "}" }
		return fmt.Sprintf("DRIVER={Vertica};SERVER=%s;PORT=%d;DATABASE=%s;UID=%s;PWD=%s", escape(c.Host), c.Port, escape(c.Database), escape(c.Username), escape(c.Password))
	}
	u := url.URL{Scheme: "postgresql", Host: net.JoinHostPort(c.Host, strconv.Itoa(c.Port)), Path: "/" + c.Database}
	u.User = url.User(c.Username)
	if password && c.Password != "" {
		u.User = url.UserPassword(c.Username, c.Password)
	}
	q := url.Values{}
	for k, v := range c.Params {
		q.Set(k, v)
	}
	u.RawQuery = q.Encode()
	return u.String()
}

func luaString(s string) string {
	var b strings.Builder
	b.WriteByte('"')
	for _, r := range s {
		switch r {
		case '\\', '"':
			b.WriteByte('\\')
			b.WriteRune(r)
		default:
			if r < 32 || r == 127 {
				fmt.Fprintf(&b, "\\%03d", r)
			} else {
				b.WriteRune(r)
			}
		}
	}
	b.WriteByte('"')
	return b.String()
}

func renderCatalog(catalog map[string]connection) (map[string][]byte, error) {
	profiles := map[string]any{}
	rain := map[string]any{}
	lua := map[string][]string{}
	for _, id := range sortedKeys(catalog) {
		c := catalog[id]
		if contains(c.Tools, "harlequin") {
			adapter := c.Driver
			if adapter == "vertica" {
				adapter = "odbc-vertica"
			}
			profile := map[string]any{"adapter": adapter, "conn_str": []string{connectionURL(c, true)}, "limit": 1000}
			if c.Driver == "h2" {
				profile["user"] = c.Username
				profile["password"] = c.Password
			}
			profiles[strings.ReplaceAll(id, "-", "_")] = profile
		}
		if contains(c.Tools, "rainfrog") {
			rain[id] = map[string]any{"connection_string": connectionURL(c, false), "driver": c.Driver}
		}
		if contains(c.Tools, "nvim") {
			lua[c.Project] = append(lua[c.Project], fmt.Sprintf("  { name = %s, url = %s },", luaString(c.Label), luaString(connectionURL(c, true))))
		}
	}
	outputs := map[string][]byte{}
	for name, value := range map[string]any{"harlequin.toml": map[string]any{"profiles": profiles}, "rainfrog_config.toml": map[string]any{"db": rain}} {
		data, err := encodeTOML(value)
		if err != nil {
			return nil, err
		}
		outputs[name] = append([]byte("# Generated by db sync. Do not edit.\n"), data...)
	}
	for project, lines := range lua {
		outputs[filepath.Join("nvim", project+".lua")] = []byte("-- Generated by db sync. Do not edit.\nreturn {\n" + strings.Join(lines, "\n") + "\n}\n")
	}
	return outputs, nil
}

func syncCatalog() (map[string]connection, error) {
	source, err := sourcePath()
	if err != nil {
		return nil, err
	}
	catalog, err := readCatalog(source)
	if err != nil {
		return nil, err
	}
	outputs, err := renderCatalog(catalog)
	if err != nil {
		return nil, err
	}
	root := filepath.Join(configBase(), "db")
	for _, name := range sortedKeys(outputs) {
		path := filepath.Join(root, name)
		existing, err := os.ReadFile(path)
		info, statErr := os.Lstat(path)
		if err == nil && statErr == nil && info.Mode().IsRegular() && info.Mode().Perm() == 0o600 && bytes.Equal(existing, outputs[name]) {
			continue
		}
		if err := writePrivate(path, outputs[name]); err != nil {
			return nil, err
		}
	}
	// Only remove our own retired Neovim outputs, never arbitrary user files.
	stale, err := filepath.Glob(filepath.Join(root, "nvim", "*.lua"))
	if err != nil {
		return nil, err
	}
	for _, path := range stale {
		if _, ok := outputs[filepath.Join("nvim", filepath.Base(path))]; ok {
			continue
		}
		data, err := os.ReadFile(path)
		if err != nil {
			return nil, err
		}
		if bytes.HasPrefix(data, []byte("-- Generated by db sync. Do not edit.\n")) {
			if err := os.Remove(path); err != nil {
				return nil, err
			}
		}
	}
	return catalog, nil
}
