<a href="https://goose-docs.ai">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/aaif-goose/goose/main/documentation/static/img/goose-logo-white.png">
    <img alt="goose" src="https://raw.githubusercontent.com/aaif-goose/goose/main/documentation/static/img/goose-logo-black.png" height="48">
  </picture>
</a>

<sub>goose™ is a trademark of LF Projects, LLC. goose is an Agentic AI Foundation (AAIF) project, originally created by Block. The logo is the unmodified official asset from <a href="https://github.com/aaif-goose/goose">aaif-goose/goose</a>, used to refer to the project per the <a href="https://lfprojects.org/policies/trademark-policy/">LF Projects trademark policy</a>. No endorsement implied.</sub>

# Goose agent setup with xAI Grok (Warble)

Goose is our recommended **local AI agent** (CLI + TUI). It runs on your machine, uses tools (shell, edit, MCP), and bills through whichever provider you configure. Warble routing: **Anthropic while org credits last, then xAI** ([05](./05-cost-optimization-2h.md#credit-routing-warble-policy)). This page walks through the xAI provider; for Anthropic see [06](./06-anthropic-cli-credits.md#goose--anthropic).

- Docs: [https://goose-docs.ai](https://goose-docs.ai)  
- Providers: [https://goose-docs.ai/docs/getting-started/providers](https://goose-docs.ai/docs/getting-started/providers)  
- Install: see official install for your OS, or use a release binary

Warble engineers already often have `goose` on `PATH` (e.g. `~/.local/bin/goose`).

---

## Prerequisites

1. [xAI console API key](./01-xai-console-setup.md)  
2. Credits + spend limit ([cost guide](./02-xai-payg-costs.md))  
3. Dev toolchain from [warble-onboarding README](../README.md) (git, jq, etc.)

```bash
goose --version    # e.g. 1.43+
goose doctor       # optional health check
```

---

## Configure xAI as provider

### Option A — interactive (recommended first time)

```bash
goose configure
```

When prompted:

1. Choose provider **xAI** (Grok).  
2. Paste `XAI_API_KEY`.  
3. Select model **`grok-4.5`** for default agent work.  
4. Leave host default unless you have a custom gateway.

### Option B — environment variables

```bash
# ~/.zshrc or direnv .envrc (never commit secrets)
export XAI_API_KEY='xai-...'
export GOOSE_PROVIDER='xai'          # or 'anthropic' while org credits last (see 06)
export GOOSE_MODEL='grok-4.5'
# export XAI_HOST='https://api.x.ai/v1'  # only if required (Goose default)
```

Goose also supports quick setup from an API key in Desktop / first-run UX (detects provider from key shape).

Config file location (this machine pattern):

```text
~/.config/goose/config.yaml
```

Keep secrets out of git. Prefer env vars or OS keychain if available.

---

## Daily commands

| Command | Use |
|---------|-----|
| `goose session` / `goose s` | Interactive agent in current directory |
| `goose term` | Shell integration (`@goose` / `@g` from your prompt) |
| `goose run -i instructions.md` | Non-interactive from a file |
| `goose review` | Review current git diff |
| `goose recipe ...` | Shared recipes / deeplinks |
| `goose skills` | Skill utilities |
| `goose mcp` | Bundled MCP servers |

### Start in the right repo

```bash
cd ~/warble-opensource/warble-api   # or enterprise path
goose session
```

Avoid launching Goose from a parent of **many** large clones unless the task needs them — context and tool scope explode cost.

---

## Recommended Warble defaults

| Setting | Value | Why |
|---------|-------|-----|
| Provider | Anthropic while org credits last, then xAI | Warble credit routing ([05](./05-cost-optimization-2h.md#credit-routing-warble-policy)) |
| Model | `grok-4.5` | Coding + tools |
| Cheap alternate | `grok-4.3` or `grok-build-0.1` / fast SKU | Bulk / low stakes |
| Telemetry | off if privacy preferred | `GOOSE_TELEMETRY_ENABLED: false` already used on some boxes |
| Working dir | Single service repo | Lower token burn |

Example minimal `~/.config/goose/config.yaml` fragment (names may vary by goose version — use `goose configure` if unsure):

```yaml
GOOSE_TELEMETRY_ENABLED: false
# Provider/model often stored after `goose configure`; prefer env for keys:
# XAI_API_KEY is read from the environment
```

---

## Extensions & MCP

Goose speaks **MCP**. Enable only what you need:

- Filesystem / shell (default agent power)  
- GitHub MCP (PRs/issues) — use fine-scoped tokens  
- Browser / web — costs + noise; off by default for pure backend work  

Warble repos may also use **Grok Build** skills under `.grok/`; Goose skills are parallel — don’t enable both stacks blindly on the same task.

---

## Safety

Goose can run shell commands and edit files. Treat it as **you with automation**:

1. Prefer clean git state; commit or stash before large agent runs.  
2. Don’t paste production DB credentials into prompts.  
3. Use branch-per-task; review `git diff` before push.  
4. For destructive ops (force push, prod apply), require human confirmation culture.  
5. Rotate `XAI_API_KEY` if it appears in logs or chat transcripts.

---

## Cost-aware Goose habits

See [02-xai-payg-costs.md](./02-xai-payg-costs.md). Short version:

- Restart sessions when the thread is huge.  
- Point at one repo.  
- Use cheaper models for “summarize this log”.  
- Cap console spend for laptop keys.  
- Don’t leave multi-agent recipes running unattended overnight.

---

## Troubleshooting

| Symptom | Check |
|---------|--------|
| Auth errors | `echo ${#XAI_API_KEY}`, console key active, credits &gt; 0 |
| Model not found | Exact model id from console / docs.x.ai |
| Goose can’t find provider | Re-run `goose configure`; upgrade goose (`goose update`) |
| Slow / huge bills | Context size, tool loops, long-context pricing tier |
| Doctor fails | Network, key, disk permissions on config dirs |

```bash
goose doctor
goose info
```

---

## Optional: side-by-side with Grok Build TUI

Some Warble workflows use **Grok Build** (`.grok/` skills, subagents). Goose is the **default open agent** for day-to-day; pick one agent per task to avoid double spend.

| | Goose | Grok Build |
|--|-------|------------|
| Open source agent | Yes | xAI product UX |
| Local tools | Strong | Strong |
| Billing | Your xAI API key | Your xAI API / product key path |
| Skills | Goose skills / MCP | `.grok/skills`, workflows |

---

Next: [04-warble-usage-playbook.md](./04-warble-usage-playbook.md)
