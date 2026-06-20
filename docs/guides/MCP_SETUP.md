# 🔌 MCP setup

> Model Context Protocol servers extend an agent's capabilities (file-system
> indexes, code-graph lookups, search, browser, ...). This repo wires them
> in three places so every assistant sees the same set.

## Files

| Path | Read by |
|---|---|
| [`.mcp.json`](../../.mcp.json) | Claude Code, generic MCP clients. |
| [`.vscode/mcp.json`](../../.vscode/mcp.json) | VS Code Copilot. |
| [`.cursor/mcp.json`](../../.cursor/mcp.json) | Cursor. |

Keep the `mcpServers` block synchronised across the three for any
**project-scoped** servers you add.

## CodeGraph

[CodeGraph](https://github.com/colbymchenry/codegraph) gives agents a pre-indexed
symbol graph — ~58% fewer tool calls, ~16% lower token cost, 100% local. It is
included in the repo MCP configs with the correct invocation:

```json
"codegraph": {
  "type": "stdio",
  "command": "npx",
  "args": ["-y", "@colbymchenry/codegraph", "serve", "--mcp", "--path", "/absolute/path/to/project"]
}
```

**Two config files, two strategies:**

| File | Used by | Path strategy |
|---|---|---|
| `.vscode/mcp.json` | VS Code Copilot | `${workspaceFolder}` — VS Code expands it at runtime |
| `.mcp.json` | Claude Code, generic clients | Absolute path baked in by `scaffold.sh` |
| `.cursor/mcp.json` | Cursor | `${workspaceFolder}` — Cursor expands it |

`scaffold.sh` generates a project-specific `.mcp.json` with the absolute target
path embedded. **Never copy `.mcp.json` from this framework repo into a project
by hand** — run `scaffold.sh` so the path gets substituted correctly.

### Works alongside a global install

If you have codegraph installed globally (`codegraph install --location=global`),
VS Code and Cursor apply workspace-scope configs with higher precedence than
user-scope ones for the same server name. The workspace entry replaces the global
one in this project — no duplication, no conflict.

### First-time setup

`scaffold.sh` builds the index automatically during scaffolding (using `npx`
as a fallback when `codegraph` is not on your PATH). If you need to rebuild
it after a large refactor, or if you're adding codegraph to an existing
project that wasn't scaffolded, run:

```bash
npx @colbymchenry/codegraph init .
```

## Adding a project-scoped server

If you have an MCP server that is specific to this project (e.g. a custom
tool server living under `xops/`), add it to all three files:

1. Add the server block to `.mcp.json`, `.vscode/mcp.json`, `.cursor/mcp.json`.
2. Document its purpose + when to use it in this file.
3. If it requires secrets, document the env vars (never commit the values).
4. Add an entry to [`.agents/skills/mcp-usage/SKILL.md`](../../.agents/skills/mcp-usage/SKILL.md).

### VS Code merge semantics

VS Code Copilot **merges** the workspace `.vscode/mcp.json` with the global
`~/.config/Code/User/mcp.json`. A server name defined in both files
appears **twice** in the MCP panel, and whichever entry loads last wins (or
both fail, depending on the version). To avoid this:

- Do not put globally-installed servers (codegraph, filesystem, etc.) in `.vscode/mcp.json`.
- Only put servers that are genuinely unique to this project here.

## Anti-patterns

- Using `npx -y @pkg` without `serve --mcp` → launches the interactive installer instead of the server.
- Adding an MCP server only to `.mcp.json` → VS Code & Cursor users won't see it.
- Committing API keys in the `env` block.
- Wiring a write-capable server without a skill file explaining the blast radius.

