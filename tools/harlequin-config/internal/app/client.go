package app

import (
	"fmt"
	"strings"

	"github.com/clang-engineer/dotfiles/tools/harlequin-config/internal/catalog"
)

func harlequinProfile(c connection) map[string]any {
	adapter := c.Driver
	if adapter == "vertica" {
		adapter = "odbc-vertica"
	}
	profile := map[string]any{"adapter": adapter, "conn_str": []string{catalog.URL(c, true)}, "limit": 1000}
	if c.Driver == "h2" {
		profile["user"] = c.Username
		profile["password"] = c.Password
	}
	return profile
}

// Passwords remain in Rainfrog's platform keychain.
func rainfrogProfile(c connection) map[string]any {
	return map[string]any{"connection_string": catalog.URL(c, false), "driver": c.Driver}
}

func nvimEntry(c connection) string {
	return fmt.Sprintf("  { name = %s, url = %s },", luaString(c.Label), luaString(catalog.URL(c, true)))
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
