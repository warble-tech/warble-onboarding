# Cost optimization — ~2 hours agent work / day

Target profile for most Warble engineers: **about 2 hours of Goose / Claude Code / BrowserOS work per day**, then stop. Burn Anthropic **CLI credits first** when available; use xAI PAYG for Grok-default Goose sessions.

## Daily budget (planning)

| Layer | Prefer | Daily ballpark (2h focused) |
|-------|--------|------------------------------|
| **Anthropic Claude Code** | Use team/promo **CLI credits** first | Often **$0 cash** until credits empty |
| **Goose + Grok 4.5** | Default when not on Anthropic | **~$5–25 / day** if disciplined |
| **Goose + cheaper model** | Triage / bulk | **~$2–10 / day** |
| **BrowserOS** | Same keys as above | Counted in same token bills |

### What “disciplined 2h” means

- One primary repo open, not 19 clones at once  
- Restart Goose when context is bloated  
- Prefer Claude Code while Anthropic credits remain  
- Cap xAI console auto-recharge **off**; monthly hard limit  
- No overnight unattended multi-agent loops  

### Token math (Grok 4.5, 2h)

Assume ~20–40 medium agent turns in 2 hours:

- ~40k in + 4k out ≈ **~$0.10 / turn**  
- 25 turns ≈ **~$2.50** (small contexts)  
- Same with fat monorepo context (100k+) ≈ **~$15–30**  

**Plan: $10–20/day xAI** for active Goose days after Anthropic credits, or **~$200–400/mo** if every workday is Grok-heavy.

## Credit routing (Warble policy)

```text
1) Anthropic CLI credits  →  Claude Code (`claude`)  and Goose provider=Anthropic
2) xAI prepaid credits    →  Goose provider=xAI (grok-4.5), BrowserOS if using Grok key
3) Ollama                 →  offline / bulk / privacy experiments (no console burn)
```

### Env sketch

```bash
# Prefer Anthropic for Claude Code
export ANTHROPIC_API_KEY='...'   # or claude login / org credits

# xAI for Goose default (or switch provider in goose configure)
export XAI_API_KEY='xai-...'

# Optional: document which you use today
export WARBLE_AGENT_PRIMARY=anthropic   # or xai
```

### Goose: two providers

```bash
goose configure
# Provider A: Anthropic  → use while CLI credits last
# Provider B: xAI        → grok-4.5 for coding when on Grok budget
```

Switch model/provider when starting a session rather than mid-thread thrash.

## 2-hour session recipe

| Minute | Action |
|--------|--------|
| 0–5 | `cd` single repo, clean `git status`, note goal |
| 5–90 | Agent work (Claude Code **or** Goose, not both on same task) |
| 90–110 | Human review `git diff`, tests |
| 110–120 | Commit, push, **stop** — check console usage |

## Hard stops

- xAI daily personal spend approaching **$25** without approval  
- Anthropic credits near zero → switch to Grok or pause  
- Session context past ~150k tokens → **new session** (avoid 200k long-context cliff on Grok)

## Monthly review

1. Console.x.ai usage by key  
2. Anthropic usage / remaining credits  
3. Adjust primary agent for next month  

See also: [02-xai-payg-costs.md](./02-xai-payg-costs.md) · [03-goose-agent-setup.md](./03-goose-agent-setup.md)
