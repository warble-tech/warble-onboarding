# AGENTS.md — warble-onboarding

Instructions for AI coding agents (Goose, Antigravity, Claude Code, etc.) working in this repo.
Humans: see [README.md](./README.md) and [ai/08-managing-agents.md](./ai/08-managing-agents.md).

## What this repo is
Onboarding scripts (bash for Linux/macOS, PowerShell for Windows) plus markdown docs under `ai/`.

## Checks to run after editing
- Shell: `bash -n <file>` and `shellcheck -S warning linux/*.sh mac/*.sh`
- PowerShell: parse with `[System.Management.Automation.Language.Parser]::ParseFile(...)` or PSScriptAnalyzer
- Docs: every link you add must resolve. Use official vendor URLs only and never invent download links.

## Rules
- **Do not run the installers** (`install-devtools.sh`, `setup.sh`, `setup.ps1`, `apply.sh`, ...). They use sudo and change the host. Edit and lint only.
- Docker / kind stay **OFF by default** on every platform.
- When you add a tool, add it to every OS installer it applies to, plus `README.md` and `ai/README.md`.
- Keep `ai/` numbering (`NN-topic.md`) and update the index table in `ai/README.md`.
- Credit routing: Anthropic CLI credits first, then xAI (see `ai/05-cost-optimization-2h.md`). Don't contradict it.
- Never commit secrets or real API keys. Examples use the placeholders `xai-...` / `sk-ant-...`.
- Don't push to `main`, force-push, or merge. Open a PR and let a human review it.
