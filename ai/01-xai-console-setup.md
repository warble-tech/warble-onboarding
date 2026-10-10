# xAI Console setup (Warble)

Console: [https://console.x.ai](https://console.x.ai)  
Docs: [https://docs.x.ai](https://docs.x.ai)

## 1. Account & org

1. Sign in at **console.x.ai** with a `@warblecloud.com` (or approved) email when possible.
2. Join the **Warble** team/org if one exists; otherwise create a personal project and later migrate keys under org billing.
3. Enable 2FA on the account.

### Domain ownership

Grok/xAI may ask for **domain verification** via a DNS TXT record:

```text
Type: TXT
Name: @   (or the hostname they show)
Content: domain-verification=<hex token>
```

Warble already publishes verification TXT records for primary domains via Cloudflare. If console still fails:

- Confirm the **exact host** (apex vs a subdomain such as `grok.example.com`).
- Wait for DNS (usually minutes on Cloudflare).
- Re-check with public DNS:  
  `dig TXT warblecloud.com +short` (or Cloudflare dashboard → DNS).

## 2. Create an API key

1. Console → **API Keys** → **Create API key**.
2. Name it clearly, e.g. `avinash-laptop-goose`, `ci-warble-core`.
3. Copy once; store in a password manager / GCP Secret Manager for shared bots.
4. Never commit keys to git. Prefer:

   | Context | Storage |
   |---------|---------|
   | Laptop Goose | `XAI_API_KEY` in `~/.config/goose/` or shell env |
   | Shared services | GCP Secret Manager (`warble-tech`) |
   | CI | GitHub Actions secret / Workload Identity + SM |

### Optional host override

Default API host is xAI’s public endpoint. Only set if docs or Goose require it:

```bash
export XAI_HOST='https://api.x.ai/v1'   # only if needed (Goose default)
```

## 3. Billing mode (PAYG)

xAI API billing is **pay-as-you-go** (usage / prepaid credits), **not** the SuperGrok consumer subscription.

In console:

1. Open **Billing** / **Credits**.
2. Add a payment method.
3. Purchase **credits** (or enable auto-recharge carefully).
4. Set a **monthly spend limit** / hard cap if available — defaulting to unlimited auto-topup is risky for agents.
5. Watch **Usage** per key and model.

See [02-xai-payg-costs.md](./02-xai-payg-costs.md) for rates and Warble recommendations.

## 4. Models to enable

For Warble agent work, start with:

| Model ID | Use |
|----------|-----|
| `grok-4.5` | Default coding / agent (Goose) |
| `grok-4.3` / `grok-code-fast-1` | Cheap drafts, triage, high volume |
| `grok-build-0.1` | Coding-oriented mid tier if listed in console |
| `grok-4.7` | Newer flagship at the same in/out list price as 4.5 — evaluate before switching the default |

Confirm exact IDs under Console → Models or [docs.x.ai/developers/models](https://docs.x.ai/developers/models).

## 5. Smoke test (curl)

```bash
export XAI_API_KEY='xai-...'

curl -sS https://api.x.ai/v1/chat/completions \
  -H "Authorization: Bearer $XAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "grok-4.5",
    "messages": [{"role": "user", "content": "Reply with pong only."}],
    "max_tokens": 16
  }' | jq '.choices[0].message.content, .usage'
```

If this works, Goose can use the same key.

## 6. Team checklist

- [ ] Org membership + 2FA  
- [ ] Domain verified for company email / branding if required  
- [ ] Personal API key created and named  
- [ ] Credits funded + spend limit set  
- [ ] Key stored outside git  
- [ ] Curl smoke test OK  
- [ ] Goose configured ([03](./03-goose-agent-setup.md))  

## 7. Security notes

- Rotate keys if a laptop is lost or a key is pasted into chat/logs.
- Prefer **one key per human / per service** for attribution in usage dashboards.
- Do not put production secrets into Goose sessions unless required; use MCP/tools with least privilege.
- Agent sessions can run shell commands — treat Goose like a privileged local user.
