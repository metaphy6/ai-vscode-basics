# 🧰 ai-vscode-basics

> **A model-agnostic scaffold for repositories where AI coding agents do real work.**
> Drop-in instructions, configs, skills, tracking, and a tiny Makefile + xops layer
> that work the same across **GitHub Copilot, Claude, Gemini, Codex CLI, Cursor,
> OpenCode, Aider, and local models** (Ollama / LM Studio).

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![ShellCheck](https://img.shields.io/badge/shellcheck-passing-brightgreen)](https://www.shellcheck.net/)
[![shfmt](https://img.shields.io/badge/shfmt-formatted-blue)](https://github.com/mvdan/sh)
[![Scaffolded with](https://img.shields.io/badge/scaffolded--with-v1.0.0-blueviolet)](.ai-vscode-basics-version)
[![Works with 8 agents](https://img.shields.io/badge/works%20with-8%20agents-orange)](docs/guides/MODEL_PROFILES.md)

> **Note:** this README describes the framework repo itself. When you scaffold
> into a target project, the target gets a small project-template `README.md`
> instead — and the `.ai-vscode-basics-version`, `install.sh`, and
> `xops/init/scaffold.sh` files are intentionally **not** copied into it.

---

## ⚡ Quickstart in 60 seconds

```bash
# 1. One-liner install (scaffolds into ./my-repo, creates it if needed)
curl -fsSL https://raw.githubusercontent.com/metaphy6/ai-vscode-basics/main/install.sh \
  | bash -s -- --target ./my-repo
```

```bash
# 2. Or clone + scaffold manually (scaffold.sh lives in the framework repo)
git clone https://github.com/metaphy6/ai-vscode-basics.git ~/code/ai-vscode-basics
~/code/ai-vscode-basics/xops/init/scaffold.sh --target ./my-repo
```

```bash
# 3. Verify + orient the first agent session
cd ./my-repo
make doctor
xops/agent/session-bootstrap.sh
```

---

## 🎯 What this is

`ai-vscode-basics` is a **bootstrapper** (not a template you fork). You keep this
repo around once, then scaffold its agent framework into any new or existing
project with one command:

```bash
xops/init/scaffold.sh --target /path/to/your-project
```

It gives every project the same shape:

- 📜 **One rulebook (`AGENTS.md`)** that every AI assistant reads first, plus
  thin per-vendor entry points (`CLAUDE.md`, `GEMINI.md`, `CONVENTIONS.md`,
  `.github/copilot-instructions.md`, `.cursor/rules/`, `.codex-plugin/`, …)
  that all delegate back to it. No drift between assistants.
- 📊 **A 9-column [`docs/tracking/tracking.csv`](docs/tracking/tracking.csv)** that
  records every meaningful agent action (plan / implement / test / review /
  commit / revert / note / block) — the single source of truth `make git` reads
  to build commit messages.
- 🤖 **`make git` / `make git.dry`** — agents never run `git commit` / `git push`;
  they append a tracking row and stage files, the human (or `make git`) commits.
- 🗺️ **A `ROADMAP.md` template** + `docs/{code,project,design,planning,tracking,guides}`
  layout so agents always know where to put things.
- 🧪 **`xops/`** — a tiny ops tree with `safe-run.sh` (crash-safe command wrapper),
  `session-bootstrap.sh` (orient a fresh agent session), `tracking_append.sh`
  (validated CSV appender), and Python ops scripts for `make git`.
- 🧠 **`.agents/skills/`** — a curated, general-purpose skill library (TDD,
  systematic debugging, code review, documentation discipline, MCP usage,
  parallel subagents, AI output stability, …) that any project can benefit from.
  Skills live under `.agents/skills/<name>/SKILL.md` and are accessible via
  the VS Code Copilot `/` command.

CI/CD, language-specific tooling, and project-specific business rules are
**intentionally excluded** — those live in your project.

---

## 🚀 Scaffold options

```bash
# Dry run first (shows every file that would be created / skipped)
./xops/init/scaffold.sh --target /path/to/your-project --dry-run

# Real run (idempotent — existing files are left alone unless --force)
./xops/init/scaffold.sh --target /path/to/your-project
```

Choose a preset:

```bash
./xops/init/scaffold.sh --target /path/to/your-project --preset minimal
./xops/init/scaffold.sh --target /path/to/your-project --preset full   # default
```

Pick exactly which agent surfaces you want:

```bash
./xops/init/scaffold.sh --target /path/to/your-project \
  --agents copilot,claude,gemini --no-cursor --no-aider
```

Add a language preset:

```bash
./xops/init/scaffold.sh --target /path/to/your-project --lang python
# also: node | go | rust — adds .gitignore lines + Makefile.lang.mk
```

### After scaffolding

In your project:

```bash
make help          # list every target
make git.dry       # preview what would be committed (read-only)
make git           # commit pending tracking rows + push
make track.add ACTION=note SUMMARY="..."   # append a tracking row
make doctor        # sanity-check the framework is wired correctly
```

The agent in your project reads `AGENTS.md` first. That's it.

---

## 🗂️ What gets installed in a scaffolded project

| Path | Purpose |
|---|---|
| `AGENTS.md` | Master rulebook (model-agnostic). Every agent reads this first. |
| `CLAUDE.md` / `GEMINI.md` / `CONVENTIONS.md` | Vendor entry points that delegate to `AGENTS.md`. |
| `.github/copilot-instructions.md` | Copilot Chat / agent-mode rules. |
| `.github/agents/` + `.github/prompts/` | Reusable custom agents and slash-command prompts. |
| `.cursor/`, `.codex-plugin/`, `.opencode/`, `.claude-plugin/`, `.aider.conf.yml`, `gemini-extension.json` | Per-vendor wiring (mostly minimal — they all point at `AGENTS.md`). |
| `.vscode/{settings,tasks,mcp}.json` | VS Code workspace defaults. |
| `.mcp.json` | Repo-level MCP server config (CodeGraph wired; rest stubbed). |
| `Makefile` | Thin dispatcher → `xops/makefile/*.py`. |
| `docs/tracking/tracking.csv` + `docs/tracking/tracking.schema.md` | The 9-column tracking log (blank on fresh install). |
| `docs/tracking/state/` | Session state (checkpoint, last_failure, log.jsonl). |
| `docs/tracking/context.md` | Shared context pack — single file for project-specific overrides. |
| `xops/agent/` | `safe-run.sh`, `session-bootstrap.sh`, `tracking_append.sh`, `run-with-retry.sh`. |
| `xops/makefile/` | Python (stdlib only) ops scripts that `make` dispatches to. |
| `docs/` | Documentation templates (code/, project/, design/, planning/, tracking/, guides/). |
| `.agents/skills/` | Curated skill library — one `SKILL.md` per subfolder. |

The scaffolder writes a minimal **project-template `README.md`** into the target
(only if one does not already exist). The framework's own `README.md`,
`install.sh`, `xops/init/`, and `.ai-vscode-basics-version` are intentionally
not copied — those are framework-only artefacts.

See [`docs/guides/AGENT_OPERATING_MODEL.md`](docs/guides/AGENT_OPERATING_MODEL.md)
for the full design rationale, and
[`docs/guides/MODEL_PROFILES.md`](docs/guides/MODEL_PROFILES.md) for how each
assistant is wired.

---

## 📊 The tracking model in one paragraph

Agents **never** call `git commit` or `git push`. After completing a slice of
work they call `xops/agent/tracking_append.sh` to add one validated row to
`docs/tracking/tracking.csv` (9 columns: `ts_utc, run_id, agent, scope, action,
status, summary, refs, commit_sha`), then `git add -A`, then stop. The human
runs `make git` whenever they're ready; `make git` reads the rows with
`commit_sha=pending`, builds Conventional Commits from the `summary` field,
commits, and pushes. `make git.dry` previews everything read-only. The schema
lives at [`docs/tracking/tracking.schema.md`](docs/tracking/tracking.schema.md).

---

## 🧠 Skills library

`.agents/skills/` is a curated, model-agnostic library of operating practices
distilled from real-world AI-coding repos. Each skill is a subfolder with a
`SKILL.md` file (a clear *when-to-use* trigger + guidance). They are accessible
via the VS Code Copilot `/` command. See [`.agents/skills/README.md`](.agents/skills/README.md) for the index.

```bash
make skills.status          # table: skill name, line count, tags, AGENTS.md refs
make skills.find TAG=debug  # search by tag or name keyword
```

---

## 🛠️ Repo layout (the framework itself)

```
ai-vscode-basics/
├── AGENTS.md, CLAUDE.md, GEMINI.md, CONVENTIONS.md   # rulebooks
├── README.md, LICENSE, Makefile, .gitignore          # standard
├── install.sh                                        # one-liner curl installer (framework-only)
├── .ai-vscode-basics-version                         # current framework version (framework-only)
├── .github/, .cursor/, .codex-plugin/, .opencode/    # per-agent wiring
├── .claude-plugin/, .vscode/, .mcp.json, .aider.conf.yml, gemini-extension.json
├── .agents/skills/          # curated skill library (one SKILL.md per subfolder)
├── docs/
│   ├── tracking/            # tracking log + schema + state + context
│   ├── planning/ROADMAP.md
│   ├── code/, design/, project/, guides/, reports/
└── xops/
    ├── init/scaffold.sh     # ← the bootstrapper (framework-only)
    ├── agent/               # safe-run, tracking_append, session-bootstrap
    └── makefile/            # python ops dispatched by Makefile
```

---

## 🤝 Contributing

Issues and PRs welcome. The skills library especially benefits from real-world
patterns — if you have a practice that survives across projects, send a PR
adding a `SKILL.md` under a new subfolder of `.agents/skills/`.

---

## 📄 License

[MIT](LICENSE) — use freely in commercial and open-source projects.
