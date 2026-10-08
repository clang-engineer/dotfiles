package main

import "fmt"

type launcherError string

func (e launcherError) Error() string { return string(e) }

func launchTools() []string { return []string{"harlequin", "rainfrog"} }

func launchConnection(connections map[string]connection, configDir, tool, connectionID string) (int, error) {
	c, ok := connections[connectionID]
	if !ok || !contains(c.Tools, tool) {
		return 1, launcherError(fmt.Sprintf("connection is not available for %s: %s", tool, connectionID))
	}
	switch tool {
	case "harlequin":
		return launchHarlequin(connectionID, configDir)
	case "rainfrog":
		return launchRainfrog(connectionID, c)
	default:
		return 1, launcherError("unsupported launch tool: " + tool)
	}
}

func runInteractive(connections map[string]connection, configDir string) (int, error) {
	tool, connectionID, ok, err := selectConnection(connections)
	if err != nil {
		return 1, err
	}
	if !ok {
		return 130, nil
	}
	return launchConnection(connections, configDir, tool, connectionID)
}
