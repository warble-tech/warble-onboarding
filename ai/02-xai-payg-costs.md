# xAI Console — pay-as-you-go cost guide (Warble)

**Last verified against public docs:** 2026-10-11  
**Canonical rates:** [https://docs.x.ai/developers/models](https://docs.x.ai/developers/models)  
**Product (chat) plans:** [https://x.ai/pricing](https://x.ai/pricing) — *separate from API*

---

## Two different products

| | **Grok consumer / SuperGrok** | **xAI API (console.x.ai)** |
|--|-------------------------------|----------------------------|
| What | Chat product (web/app) | Token API for apps & agents |
| Billing | Monthly subscription tiers | **Pay-as-you-go** / prepaid credits |
| Used by Goose? | No (unless you use a non-API path) | **Yes** — every Goose call burns API tokens |
| Warble default | Optional for humans | **Required for agents & automation** |

Do not assume SuperGrok covers Goose. **Goose → API key → usage bills to console credits.**

---

## How PAYG works (mental model)

1. You fund the account with **credits** (or invoiced spend where enabled).
2. Each request bills **input tokens + output tokens** (and sometimes tool/search extras).
3. **Prompt caching**: repeated prefixes often bill at a **cached input** rate (much cheaper).
4. **Long-context threshold**: several models charge a **higher rate for the entire request** once the prompt exceeds ~200k tokens.
5. When credits hit $0 (and no invoiced limit), API calls fail — agents stop mid-task.
6. Optional **auto-recharge** is convenient for prod, dangerous for unbounded agent loops.

### Console knobs to set immediately

- Monthly / daily **spend cap**
- Auto-recharge **off** for personal laptop keys (or low max top-up)
- Separate keys: `dev-goose`, `prod-service`, `ci` so you can revoke and chart spend

---

## Published text API rates (per 1M tokens)

Source: xAI docs Models page. Prefer checking console if numbers diverge.

| Model | Context | Input | Cached in | Output | Notes |
|-------|---------|-------|-----------|--------|-------|
| **grok-4.5** (&lt; 200k prompt) | 500k | **$2.00** | $0.30 | **$6.00** | Default flagship for coding/agents |
| **grok-4.5** (≥ 200k prompt) | 500k | $4.00 | $0.60 | $12.00 | Whole request at long-context rates |
| **grok-4.3** (&lt; 200k) | 1M | $1.25 | $0.20 | $2.50 | Strong general / cheaper than 4.5 |
| **grok-4.3** (≥ 200k) | 1M | $2.50 | $0.40 | $5.00 | |
| **grok-4.20-*** (&lt; 200k) | 1M | $1.25 | $0.20 | $2.50 | Reasoning / non-reasoning / multi-agent variants |
| **grok-4.20-*** (≥ 200k) | 1M | $2.50 | $0.40 | $5.00 | |
| **grok-build-0.1** (&lt; 200k) | 256k | $1.00 | $0.20 | $2.00 | Coding-oriented mid tier |
| **grok-build-0.1** (≥ 200k) | 256k | $2.00 | $0.40 | $4.00 | |

> As of 2026-10-11 the models page also lists **`grok-4.6`** and **`grok-4.7`** (500k context) at $2.00 in / $0.50 cached / $6.00 out, doubling above 200k. `grok-4.1-fast` is no longer listed.

### Non-text (if you use Imagine / Voice)

| Capability | Rough public price |
|------------|--------------------|
| Image (standard / quality) | ~$0.02–$0.05 / image |
| Video | ~$0.05–$0.08 / sec |
| Voice realtime | ~$0.05 / min |

Agents rarely need these for pure code work.

---

## Rough cost math (engineers)

Approximate **single agent turn** (tool-using Goose session step):

| Scenario | Tokens (in+out) | Model | Ballpark cost |
|----------|-----------------|-------|----------------|
| Small Q&A | 5k in + 1k out | grok-4.5 | ≈ $0.01 + $0.006 → **~$0.02** |
| Medium coding turn | 40k in + 4k out | grok-4.5 | ≈ $0.08 + $0.024 → **~$0.10** |
| Large repo context | 150k in + 8k out | grok-4.5 | ≈ $0.30 + $0.05 → **~$0.35** |
| Long context spike | 250k in + 10k out | grok-4.5 long rate | ≈ $1.00 + $0.12 → **~$1.12** |
| Same medium turn | 40k + 4k | grok-4.3 / build | roughly **40–50% less** than 4.5 |

A full afternoon of agent-heavy work can be **a few dollars to tens of dollars** depending on context size and loops.

### Monthly planning (illustrative)

| Usage profile | Assumption | Order-of-magnitude |
|---------------|------------|--------------------|
| Light (reviews, small edits) | ~2M in + 0.5M out / mo on 4.5 | ~$4 + $3 ≈ **$5–15** |
| Active engineer + Goose daily | ~20M in + 4M out / mo | ~$40 + $24 ≈ **$50–100+** |
| Heavy multi-agent / CI bots | 100M+ tokens | budget **hundreds**; need caps & cheap models |

These are planning guesses — **console usage dashboard is truth**.

---

## Warble recommendations

### Model selection

| Work | Prefer | Why |
|------|--------|-----|
| Goose multi-step coding, architecture | `grok-4.5` | Best agent/coding quality |
| Bulk renames, log triage, simple scripts | fast / 4.3 / build SKU | 3–10× cheaper |
| Offline batch jobs | Batch API if available (~50% off on some tiers) | Async OK |
| Huge monorepo dumps | Avoid pasting whole tree; use tools / search | Stay under 200k long-context cliff |

### Cost controls for Goose

1. **Shorter sessions** — restart when context is bloated; long threads re-send history.
2. **Narrow the cwd** — open the repo you need, not `warble-opensource` root with 19 clones if possible.
3. **Disable expensive tools** when not needed (web search, multi-agent).
4. **One hard task per session** — “fix CI + refactor + write design doc” burns tokens.
5. **Spend limits** on console for personal keys (`$20–50/mo` starter).
6. **Shared prod keys** only on services with alerting; never on every laptop.
7. Prefer **cached-friendly** prompts (stable system instructions first).

### Funding suggestion (team)

| Bucket | Suggested start | Notes |
|--------|-----------------|-------|
| Personal Goose key | $25–50 credits, no auto-recharge | Cap manually |
| Shared staging bot | $50–100, low auto-recharge | Alert on burn rate |
| Prod product traffic | Invoiced or higher credits + dashboards | Separate key |

New accounts sometimes receive **promotional credits**; treat them as temporary.

---

## How to read a bill

1. Console → **Usage**: group by **model**, **API key**, day.
2. Spike investigation:
   - Agent loop (retries / tool thrash)
   - Accidentally selected flagship for batch job
   - Crossed **200k** long-context pricing
3. Export usage if available for finance.

---

## Consumer SuperGrok vs API (don’t mix them up)

From [x.ai/pricing](https://x.ai/pricing) (product side, changes often):

- Free / SuperGrok Lite / SuperGrok / SuperGrok Heavy / Business / Enterprise  
- These unlock **chat product** limits and features — **not** a substitute for API token billing.

For Warble **agents and automation, budget the API PAYG line item**, not only SuperGrok seats.

---

## Action checklist

- [ ] Credits loaded on org or personal console  
- [ ] Spend limit set  
- [ ] Auto-recharge policy agreed (off for laptops unless approved)  
- [ ] Default Goose model = `grok-4.5`  
- [ ] Fallback cheap model documented for bulk work  
- [ ] Monthly owner reviews usage dashboard  

Next: [03-goose-agent-setup.md](./03-goose-agent-setup.md)
