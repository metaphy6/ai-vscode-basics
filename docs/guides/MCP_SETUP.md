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

Keep the `mcpServers` block synchronised across the three.

## Default server: CodeGraph

```json
"codegraph": {
  "command": "npx",
  "args": ["-y", "@colbymchenry/codegraph"]
}
```

Use it for symbol lookup, callers / callees, route mapping. Treat it as a
discovery tool — it does not edit files.

## Adding a new server

1. Add it to all three config files.
2. Document its purpose + when to use it in this file.
3. If it requires secrets, document the env vars (never commit the values).
4. Add an entry to [`.agents/skills/mcp-usage/SKILL.md`](../../.agents/skills/mcp-usage/SKILL.md).

## Anti-patterns

- Adding an MCP server but only to `.mcp.json` → VS Code & Cursor users won't see it.
- Committing API keys in the `env` block.
- Wiring a write-capable server without a skill file explaining the blast radius.
