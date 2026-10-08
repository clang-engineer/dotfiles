package main

import (
	"fmt"
	"strings"
)

func nvimEntry(c connection) string {
	return fmt.Sprintf("  { name = %s, url = %s },", luaString(c.Label), luaString(connectionURL(c, true)))
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
