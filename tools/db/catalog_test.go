package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/BurntSushi/toml"
)

const fixture = `[local-db]
label = "Local database"
driver = "postgres"
host = "::1"
port = 5432
database = "demo"
username = "test user"
password = "secret@/?"
tools = ["harlequin", "rainfrog", "nvim"]
params = { sslmode = "disable" }
`

func setupCatalog(t *testing.T) string {
	t.Helper()
	t.Setenv("XDG_CONFIG_HOME", t.TempDir())
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, "local.toml"), []byte(fixture), 0o600); err != nil {
		t.Fatal(err)
	}
	return dir
}

func TestInitSync(t *testing.T) {
	dir := setupCatalog(t)
	if err := writePrivate(defaultConfigPath(), []byte("tool = 'harlequin'\nconnection = 'local-db'\n[extra]\nkeep = true\n")); err != nil {
		t.Fatal(err)
	}
	if err := initializeSource(dir); err != nil {
		t.Fatal(err)
	}
	cfg, raw, err := loadDBConfig()
	if err != nil || cfg.ConnectionsDir != dir || cfg.Tool != "harlequin" || raw["extra"] == nil {
		t.Fatalf("config not preserved: %v", err)
	}
	catalog, err := syncCatalog()
	if err != nil {
		t.Fatal(err)
	}
	if catalog["local-db"].Project != "local" {
		t.Fatal("project not derived from filename")
	}
	root := filepath.Join(configBase(), "db")
	for _, name := range []string{"harlequin.toml", "rainfrog_config.toml", "nvim/local.lua"} {
		path := filepath.Join(root, name)
		info, err := os.Stat(path)
		if err != nil {
			t.Fatal(err)
		}
		if info.Mode().Perm() != 0o600 {
			t.Fatal("unsafe permissions")
		}
		data, _ := os.ReadFile(path)
		if strings.HasSuffix(name, ".toml") {
			var parsed map[string]any
			if _, err := toml.Decode(string(data), &parsed); err != nil {
				t.Fatal(err)
			}
		}
		if name == "rainfrog_config.toml" && strings.Contains(string(data), "secret") {
			t.Fatal("password leaked to rainfrog")
		}
	}
	if _, err := syncCatalog(); err != nil {
		t.Fatal(err)
	}
	if _, err := saveDefault("harlequin", "local-db"); err != nil {
		t.Fatal(err)
	}
	cfg, raw, err = loadDBConfig()
	if err != nil || cfg.ConnectionsDir != dir || raw["extra"] == nil {
		t.Fatal("saveDefault lost source/nested settings")
	}
}

func TestValidationBeforeWrites(t *testing.T) {
	dir := setupCatalog(t)
	if err := initializeSource(dir); err != nil {
		t.Fatal(err)
	}
	if _, err := syncCatalog(); err != nil {
		t.Fatal(err)
	}
	output := filepath.Join(configBase(), "db", "harlequin.toml")
	before, _ := os.ReadFile(output)
	if err := os.WriteFile(filepath.Join(dir, "duplicate.toml"), []byte(fixture), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := syncCatalog(); err == nil {
		t.Fatal("duplicate IDs accepted")
	}
	after, _ := os.ReadFile(output)
	if string(before) != string(after) {
		t.Fatal("invalid catalog changed output")
	}
}

func TestDefaultSourceAndInvalidArgs(t *testing.T) {
	setupCatalog(t)
	source, err := sourcePath()
	if err != nil || source != filepath.Join(configBase(), "db", "connections") {
		t.Fatal("wrong default")
	}
	code, err := mainResult([]string{"invalid"})
	if code != 2 || err != nil {
		t.Fatal("invalid command tried to sync")
	}
	if err := initializeSource(t.TempDir()); err == nil {
		t.Fatal("empty source accepted")
	}
	if _, err := os.Stat(defaultConfigPath()); !os.IsNotExist(err) {
		t.Fatal("failed init wrote config")
	}
}

func TestRenderDriversAndEscaping(t *testing.T) {
	catalog := map[string]connection{
		"test-h2":      {Driver: "h2", URL: "jdbc:h2:mem:test", Username: "sa", Tools: []string{"harlequin"}},
		"test-vertica": {Driver: "vertica", Host: "localhost", Port: 5433, Database: "demo", Password: "a;b}", Tools: []string{"harlequin"}},
	}
	outputs, err := renderCatalog(catalog)
	if err != nil {
		t.Fatal(err)
	}
	var parsed struct {
		Profiles map[string]struct {
			Adapter string
			ConnStr []string `toml:"conn_str"`
			User    string
		}
	}
	if _, err := toml.Decode(string(outputs["harlequin.toml"]), &parsed); err != nil {
		t.Fatal(err)
	}
	if parsed.Profiles["test_h2"].User != "sa" || parsed.Profiles["test_vertica"].Adapter != "odbc-vertica" {
		t.Fatal("incorrect adapters")
	}
	if !strings.Contains(parsed.Profiles["test_vertica"].ConnStr[0], "PWD={a;b}}}") {
		t.Fatal("ODBC escaping")
	}
	c := connection{Host: "::1", Port: 5432, Username: "a b", Password: "@/", Database: "demo"}
	if got := connectionURL(c, true); got != "postgresql://a%20b:%40%2F@[::1]:5432/demo" {
		t.Fatalf("bad URL: %s", got)
	}
	if got := luaString("a\n\"\\"); got != "\"a\\010\\\"\\\\\"" {
		t.Fatalf("bad Lua: %s", got)
	}
}

func TestRainfrogSelectedProfile(t *testing.T) {
	dir := setupCatalog(t)
	if err := initializeSource(dir); err != nil {
		t.Fatal(err)
	}
	connections, err := syncCatalog()
	if err != nil {
		t.Fatal(err)
	}
	bin := t.TempDir()
	capture := filepath.Join(t.TempDir(), "capture.toml")
	t.Setenv("CAPTURE", capture)
	t.Setenv("PATH", bin+string(os.PathListSeparator)+os.Getenv("PATH"))
	script := "#!/bin/sh\ncp \"$RAINFROG_CONFIG/rainfrog_config.toml\" \"$CAPTURE\"\nprintf '%s' \"$RAINFROG_CONFIG\" > \"$CAPTURE.path\"\nexit 7\n"
	if err := os.WriteFile(filepath.Join(bin, "rainfrog"), []byte(script), 0o700); err != nil {
		t.Fatal(err)
	}
	code, err := launchRainfrog("local-db", connections["local-db"])
	if err != nil || code != 7 {
		t.Fatalf("exit status: %d %v", code, err)
	}
	var selected struct {
		DB map[string]struct {
			Default          bool
			ConnectionString string `toml:"connection_string"`
		}
	}
	if _, err := toml.DecodeFile(capture, &selected); err != nil {
		t.Fatal(err)
	}
	if len(selected.DB) != 1 || !selected.DB["local-db"].Default || strings.Contains(selected.DB["local-db"].ConnectionString, "secret") {
		t.Fatal("incorrect selected profile")
	}
	tempPath, _ := os.ReadFile(capture + ".path")
	if _, err := os.Stat(string(tempPath)); !os.IsNotExist(err) {
		t.Fatal("temporary profile leaked")
	}
}

func TestRetiredNvimOutput(t *testing.T) {
	dir := setupCatalog(t)
	if err := initializeSource(dir); err != nil {
		t.Fatal(err)
	}
	if _, err := syncCatalog(); err != nil {
		t.Fatal(err)
	}
	root := filepath.Join(configBase(), "db", "nvim")
	if err := os.WriteFile(filepath.Join(root, "manual.lua"), []byte("return {}"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, "local.toml"), []byte(strings.ReplaceAll(fixture, `"harlequin", "rainfrog", "nvim"`, `"harlequin"`)), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := syncCatalog(); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(filepath.Join(root, "local.lua")); !os.IsNotExist(err) {
		t.Fatal("retired generated profile kept")
	}
	if _, err := os.Stat(filepath.Join(root, "manual.lua")); err != nil {
		t.Fatal("manual profile removed")
	}
}

func TestPrivateWriteDoesNotFollowFileSymlink(t *testing.T) {
	root := t.TempDir()
	source := filepath.Join(root, "original")
	link := filepath.Join(root, "link")
	if err := os.WriteFile(source, []byte("original"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink(source, link); err != nil {
		t.Fatal(err)
	}
	if err := writePrivate(link, []byte("new")); err != nil {
		t.Fatal(err)
	}
	data, _ := os.ReadFile(source)
	if string(data) != "original" {
		t.Fatal("source overwritten")
	}
}
