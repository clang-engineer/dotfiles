# Claude Code Configuration Guide

An overview of Claude Code's main configuration files and how to use them.
Claude-specific public configuration lives in `chezmoi/dot_claude/`. Reusable commands
live in `chezmoi/.chezmoitemplates/agent-commands/` and chezmoi renders them into each
supported agent's native command directory.

---

## Config File Locations and Priority

Applied in descending order of precedence (higher wins):

| Priority | File | Purpose |
|---------|------|------|
| 1 | Managed Policy | Set by the org admin (enterprise) |
| 2 | `.claude/settings.local.json` | Project-local (gitignored) |
| 3 | `.claude/settings.json` | Shared project settings |
| 4 | `~/.claude/settings.json` | User-global settings |

---

## Key settings.json Options

### hooks

Defines commands that run automatically when an event occurs.

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "osascript -e 'display notification \"Task complete\" with title \"Claude Code\"'"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c '... script to block sensitive files ...'"
          }
        ]
      }
    ]
  }
}
```

**Hook event types:**

| Event | When | Purpose |
|--------|------|------|
| `PreToolUse` | Before a tool runs | Protect files, block commands |
| `PostToolUse` | After a tool runs | Auto-run lint, formatting |
| `Notification` | When waiting for user input | Send notifications |
| `Stop` | After a response completes | Post-processing tasks |

**Exit codes:**
- `0` — pass
- `2` — block (the stderr message is passed to Claude)

### permissions

Rules for allowing/blocking tool use. Composed of `allow` and `deny` arrays.

```json
{
  "permissions": {
    "allow": [
      "Read",
      "Glob",
      "Grep",
      "Bash(git status:*)",
      "WebSearch"
    ],
    "deny": [
      "Bash(rm -rf:*)"
    ]
  }
}
```

Pattern syntax: use wildcards in the form `ToolName(args:*)`.

---

## keybindings.json

Customize keyboard shortcuts. Location: `~/.claude/keybindings.json` or `.claude/keybindings.json`

```json
{
  "bindings": [
    {
      "context": "Chat",
      "bindings": {
        "ctrl+enter": "chat:submit",
        "ctrl+e": "chat:externalEditor",
        "ctrl+s": "chat:stash"
      }
    },
    {
      "context": "Global",
      "bindings": {
        "ctrl+t": "app:toggleTodos",
        "ctrl+o": "app:toggleTranscript"
      }
    }
  ]
}
```

### Key Actions

**Chat context:**
- `chat:submit` — send message
- `chat:cancel` — cancel
- `chat:externalEditor` — edit in external editor
- `chat:stash` — temporarily save input
- `chat:cycleMode` — switch mode
- `chat:modelPicker` — pick model
- `chat:thinkingToggle` — toggle thinking mode

**Global context:**
- `app:interrupt` — interrupt
- `app:exit` — exit
- `app:toggleTodos` — toggle task panel
- `app:toggleTranscript` — toggle transcript
- `history:search` — search history

**Key syntax:**
- Modifiers: `ctrl`, `alt`, `shift`, `meta`/`cmd`
- Special keys: `escape`, `enter`, `tab`, `space`, `up`, `down`
- Chord keys: `ctrl+k ctrl+s` (pressed in sequence)
- Assign `null` to unbind the default binding

---

## CLAUDE.md / .claude/rules/

How to pass project-specific instructions to Claude Code.

### CLAUDE.md (repo root)

Write the project overview, build commands, and coding conventions. Loaded automatically at the start of a conversation.

```markdown
# Project Name

## Build commands
npm run build

## Coding conventions
- Use TypeScript strict mode
- Function names in camelCase
```

### .claude/rules/

You can split topic-specific rules into individual files.

```
.claude/rules/
├── testing.md      # test-writing rules
├── security.md     # security-related rules
└── naming.md       # naming rules
```

Loaded automatically, just like `CLAUDE.md`.

---

## MCP Server Configuration (mcp.json)

Connect external tool servers to Claude Code. Location: `.claude/mcp.json`

```json
{
  "mcpServers": {
    "serena": {
      "command": "uvx",
      "args": ["serena"],
      "env": {
        "SERENA_PROJECT_DIR": "/path/to/project"
      }
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-filesystem", "/path/to/dir"]
    }
  }
}
```

**Scope by config location:**
- `~/.claude/mcp.json` — global (all projects)
- `.claude/mcp.json` — project-only

---

## Creating Slash Commands

Create a markdown file in the `.claude/commands/` directory and it becomes usable as `/command`.
Commands that also work in Codex or OpenCode belong in
`chezmoi/.chezmoitemplates/agent-commands/` instead; chezmoi distributes them to all
three tools.

```
.claude/commands/
├── review.md       →  /review
├── test.md         →  /test
└── deploy.md       →  /deploy
```

**Example file contents** (`.claude/commands/review.md`):

```markdown
Review the code. Check from these angles:
- Security vulnerabilities
- Performance issues
- Coding convention violations

Focus your review on the $ARGUMENTS files.
```

- `$ARGUMENTS` — replaced with the text typed after the slash command
- Global commands: place them in `~/.claude/commands/`

---

## Environment Variables

Key environment variables that control Claude Code's behavior:

| Variable | Description | Example |
|------|------|------|
| `ANTHROPIC_MODEL` | Specify the model to use | `claude-sonnet-4-6` |
| `CLAUDE_CODE_USE_BEDROCK` | Use AWS Bedrock | `1` |
| `CLAUDE_CODE_USE_VERTEX` | Use GCP Vertex | `1` |
| `ANTHROPIC_API_KEY` | API key (when set directly) | `sk-ant-...` |
| `CLAUDE_CODE_MAX_TURNS` | Max turns in non-interactive mode | `10` |
| `DISABLE_PROMPT_CACHING` | Disable prompt caching | `1` |

---

## Tips

- **Check settings**: run the `/config` command inside Claude Code to view the current settings
- **Hook debugging**: stderr output is passed to Claude, so debug with `echo "debug info" >&2`
- **Permission management**: `settings.local.json` is not committed to git, so you can keep per-machine permissions separate
- **Sharing slash commands**: commit `.claude/commands/` to the repo so the whole team can use them
