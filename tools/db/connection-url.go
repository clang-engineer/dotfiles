package main

import (
	"fmt"
	"net"
	"net/url"
	"strconv"
	"strings"
)

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
