# Warble AI Onboarding — Anthropic + Grok (xAI) + Goose

Warble routes agent work **Anthropic CLI credits first** (Claude Code / Goose-Anthropic), then **xAI Grok** pay-as-you-go (console + API). **[Goose](https://goose-docs.ai)** is the primary local coding agent on either provider. Single source of truth for routing: [05 — Credit routing](./05-cost-optimization-2h.md#credit-routing-warble-policy).

| Doc | Purpose |
|-----|---------|
| [01 — xAI Console setup](./01-xai-console-setup.md) | Account, API keys, domain verification, team access |
| [02 — Pay-as-you-go costs](./02-xai-payg-costs.md) | How billing works, model rates, Warble cost habits |
| [03 — Goose agent setup](./03-goose-agent-setup.md) | Install, point Goose at xAI / Anthropic, daily workflows |
| [04 — Warble usage playbook](./04-warble-usage-playbook.md) | Which model for which task; secrets; repos |
| [05 — 2h/day cost optimization](./05-cost-optimization-2h.md) | Daily budget, credit routing, hard stops |
| [06 — Anthropic CLI credits](./06-anthropic-cli-credits.md) | Claude Code + using org Anthropic credits first |
| [07 — Google Antigravity](./07-antigravity-setup.md) | Optional: Antigravity desktop / `agy` CLI — install, permission presets, rules, MCP |

## Quick start (engineers)

1. **Prefer Anthropic CLI credits** for Claude Code / Goose-Anthropic while they last → [06](./06-anthropic-cli-credits.md).
2. Get an xAI API key at [console.x.ai](https://console.x.ai) for Grok-backed Goose → [01](./01-xai-console-setup.md).
3. Store keys locally (never commit):

   ```bash
   export ANTHROPIC_API_KEY='sk-ant-...'   # or claude login
   export XAI_API_KEY='xai-...'
   ```

4. Install toolchain (includes **Goose**, **Claude Code**, **BrowserOS**):

   ```bash
   # linux example
   bash warble-onboarding/linux/install-devtools.sh
   goose configure   # Anthropic and/or xAI
   ```

5. Target **~2 hours agent work/day** → [05](./05-cost-optimization-2h.md).  
   Default Grok model when on xAI: **`grok-4.5`**.

## Domain verification

Warble domains already have Grok / xAI TXT verification on Cloudflare for:

- `warblecloud.com` (apex + `grok.warblecloud.com`)
- `warblecloud.ai`
- `frakma.io`

DNS is managed via Cloudflare API; token lives in GCP Secret Manager (`warble-tech` / `cloudflare-api-token`).

## Managing agents

Day-to-day rules for running agents safely (worktrees, permission modes, `AGENTS.md`, MCP and secrets hygiene):
→ **[08 — Managing AI agents](./08-managing-agents.md)**. The repo root [AGENTS.md](../AGENTS.md) is what agents read in this repo.

## Related tooling

| Tool | Role |
|------|------|
| **Goose** | Primary local coding agent (xAI and/or Anthropic) |
| **Claude Code** (`claude`) | Anthropic CLI — **use org credits first** |
| **BrowserOS** | Agentic Chromium; BYO keys (xAI / Anthropic / Ollama) |
| **xAI API** (`api.x.ai`) | PAYG tokens for Goose/Grok, apps, CI |
| **Grok chat / SuperGrok** | Product UI (subscription; not API credits) |
| **Ollama** | Local models; no console burn |

### Containers (policy)

**Docker CE / Docker Desktop is off by default** in onboarding. Prefer remote **GKE**.  
Opt-in local Docker: `WARBLE_INSTALL_DOCKER=1` (Linux) or enable in Windows checklist / `brew install --cask docker|rancher` (macOS).

Product subscriptions (SuperGrok, etc.) are **separate** from API spend. API is prepaid credits / PAYG — see cost guide.
