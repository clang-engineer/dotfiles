package main

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"strings"
)

func previewTool(connections map[string]connection, tool string) {
	entries := availableConnections(connections, tool, "")
	projects := map[string]bool{}
	drivers := map[string]bool{}
	for _, entry := range entries {
		projects[entry.Project] = true
		drivers[entry.Driver] = true
	}
	fmt.Printf("Tool: %s\n", tool)
	fmt.Printf("Projects: %d\n", len(projects))
	fmt.Printf("Connections: %d\n", len(entries))
	fmt.Printf("Drivers: %s\n", strings.Join(sortedKeys(drivers), ", "))
}

func previewProject(connections map[string]connection, tool, project string) {
	entries := availableConnections(connections, tool, project)
	fmt.Printf("Project: %s\n", project)
	fmt.Printf("Tool: %s\n\n", tool)
	fmt.Println("Connections:")
	for _, id := range sortedKeys(entries) {
		fmt.Printf("  %s  %s\n", id, entries[id].Label)
	}
}

func previewConnection(connections map[string]connection, tool, connectionID string) error {
	conn, ok := connections[connectionID]
	if !ok || !contains(conn.Tools, tool) {
		return launcherError(fmt.Sprintf("connection is not available for %s: %s", tool, connectionID))
	}
	fmt.Printf("ID: %s\n", connectionID)
	fmt.Printf("Label: %s\n", conn.Label)
	fmt.Printf("Driver: %s\n", conn.Driver)
	if conn.Driver == "h2" {
		fmt.Printf("URL: %s\n", conn.URL)
	} else {
		fmt.Printf("Host: %s:%d\n", conn.Host, conn.Port)
		fmt.Printf("Database: %s\n", conn.Database)
	}
	fmt.Printf("Username: %s\n", conn.Username)
	return nil
}

func shellQuote(value string) string { return "'" + strings.ReplaceAll(value, "'", "'\\''") + "'" }

func pick(items []string, prompt string, previewArgs []string, dbRows bool, escapeAction string) (string, bool, error) {
	if _, err := exec.LookPath("fzf"); err != nil {
		return "", false, launcherError("fzf is required for interactive selection")
	}
	script, err := os.Executable()
	if err != nil {
		return "", false, err
	}
	previewParts := []string{shellQuote(script)}
	for _, arg := range previewArgs {
		previewParts = append(previewParts, shellQuote(arg))
	}
	preview := strings.Join(previewParts, " ")
	if dbRows {
		preview += " {1}"
	} else {
		preview += " {}"
	}
	args := []string{"--height=40%", "--layout=reverse", "--border", "--prompt=" + prompt + "> ", "--preview=" + preview, "--preview-window=right:45%", "--header=Esc: " + escapeAction}
	if dbRows {
		args = append(args, "--delimiter=\t", "--with-nth=1,2")
	}
	cmd := exec.Command("fzf", args...)
	cmd.Stdin = strings.NewReader(strings.Join(items, "\n") + "\n")
	var out bytes.Buffer
	cmd.Stdout = &out
	err = cmd.Run()
	if exitErr, ok := err.(*exec.ExitError); ok && exitErr.ExitCode() == 130 {
		return "", false, nil
	}
	if err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok {
			return "", false, launcherError(fmt.Sprintf("fzf failed with exit status %d", exitErr.ExitCode()))
		}
		return "", false, err
	}
	selection := strings.TrimSuffix(out.String(), "\n")
	if selection == "" {
		return "", false, launcherError("fzf returned an empty selection")
	}
	if dbRows {
		selection = strings.SplitN(selection, "\t", 2)[0]
	}
	return selection, true, nil
}

func selectConnection(connections map[string]connection) (string, string, bool, error) {
	for {
		tool, ok, err := pick(launchTools(), "tool", []string{"--preview-tool"}, false, "exit")
		if err != nil || !ok {
			return "", "", false, err
		}
		for {
			entries := availableConnections(connections, tool, "")
			projectsSet := map[string]bool{}
			for _, entry := range entries {
				projectsSet[entry.Project] = true
			}
			project, ok, err := pick(sortedKeys(projectsSet), "project", []string{"--preview-project", tool}, false, "back")
			if err != nil {
				return "", "", false, err
			}
			if !ok {
				break
			}
			for {
				projectEntries := availableConnections(connections, tool, project)
				rows := []string{}
				for _, id := range sortedKeys(projectEntries) {
					rows = append(rows, id+"\t"+projectEntries[id].Label)
				}
				connectionID, ok, err := pick(rows, "database", []string{"--preview-connection", tool}, true, "back")
				if err != nil {
					return "", "", false, err
				}
				if !ok {
					break
				}
				return tool, connectionID, true, nil
			}
		}
	}
}
