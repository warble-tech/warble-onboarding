# Warble usage playbook — Grok + Goose

How we use Grok day-to-day across open-source and enterprise repos.

## Repo map (local)

Typical layout after clone:

```text
~/src/oss/                    # open-source repos
  warble-onboarding/          # this guide lives under ai/
  ...

~/src/internal/               # private product repos
  ...
```

**Goose rule:** `cd` into the smallest repo that owns the change.

## Task → model / tool

Provider routing follows [05 — Credit routing](./05-cost-optimization-2h.md#credit-routing-warble-policy): Anthropic CLI credits first, then xAI. The **Model** column below is the xAI choice when you are on the Grok budget.

| Task | Agent | Model | Notes |
|------|-------|-------|-------|
| Feature implementation | Goose | `grok-4.5` | Branch first |
| Bugfix + tests | Goose | `grok-4.5` | Point at failing test output |
| PR review of own diff | `goose review` | `grok-4.5` | |
| Log / alert triage | Goose | fast / 4.3 | Cheaper |
| Design / ADR draft | Goose or Grok chat | `grok-4.5` | Human edits final ADR |
| DNS / Cloudflare ops | Human + small scripts | — | Token in GCP SM |
| K8s / bootstrap | Goose with narrow path | `grok-4.5` | No blind prod apply |
| Marketing copy | Chat UI ok | any | Low risk |

## Secrets & infra references

| Secret / resource | Where |
|-------------------|--------|
| DNS / Cloudflare API tokens | Team secret manager (e.g. GCP Secret Manager) — never in git |
| xAI API keys | Personal env, or team secret manager if centralizing |
| Grok domain TXT | Your DNS provider |

## Suggested team conventions

1. **Key naming:** `warble-<who>-<device>-goose` in console.  
2. **Spend:** personal keys default **no auto-recharge**; monthly cap.  
3. **Commits:** agent may draft; human authors final commit messages and review.  
4. **PRs:** never force-push shared branches from an agent without asking.  
5. **Incidents:** prefer human-driven runbooks; agent for search/summarize only.  

## Example first week

**Day 1**

- Console account, credits, spend limit  
- `XAI_API_KEY` + curl smoke test  
- `goose configure` → xAI → `grok-4.5`  
- `goose session` in `warble-onboarding` and ask for a doc nits pass  

**Day 2–3**

- Real task in one service repo  
- Practice `goose review` on a PR branch  
- Check console usage once  

**Day 4+**

- Add MCP only if needed (GitHub)  
- Document personal cost baseline for the month  

## Links

- [xAI models & pricing](https://docs.x.ai/developers/models)  
- [xAI console](https://console.x.ai)  
- [Goose docs](https://goose-docs.ai)  
- Internal: [01 console](./01-xai-console-setup.md) · [02 costs](./02-xai-payg-costs.md) · [03 goose](./03-goose-agent-setup.md)
