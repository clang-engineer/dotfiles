package app

import "github.com/clang-engineer/dotfiles/tools/harlequin-config/internal/catalog"

func harlequinProfile(c connection) map[string]any {
	adapter := c.Driver
	if adapter == "vertica" {
		adapter = "odbc-vertica"
	}
	profile := map[string]any{"adapter": adapter, "conn_str": []string{catalog.URL(c)}, "limit": 1000}
	if c.Driver == "h2" {
		profile["user"] = c.Username
		profile["password"] = c.Password
	}
	return profile
}
