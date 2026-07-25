# Anthropic CLI credits (Claude Code)

Warble has **Anthropic CLI credits** — use them for terminal agent work so we do not burn xAI PAYG for every session.

## Install

Installed by platform scripts as **Claude Code**:

```bash
# already in install-devtools if npm/node present
npm install -g @anthropic-ai/claude-code@latest
claude --version
```

## Auth

```bash
claude
# or
export ANTHROPIC_API_KEY='sk-ant-...'
```

Use org / team login when credits are on a shared Anthropic account.

## When to use Claude Code vs Goose

| Use **Claude Code** (`claude`) | Use **Goose** |
|--------------------------------|---------------|
| Anthropic credits remaining | Credits exhausted or task needs Goose skills/MCP |
| Deep single-repo coding | Multi-tool / custom recipes |
| Quick PR-sized tasks | xAI Grok preferred for that day |

**Do not run both agents on the same uncommitted tree** without coordination — double edits and double bill.

## Goose + Anthropic

```bash
goose configure
# select Anthropic provider
# paste ANTHROPIC_API_KEY or use existing auth
```

Same credits apply when Goose routes through Anthropic.

## Security

- Keys in env / secret manager only  
- One key per human when possible  
- Rotate if pasted into logs  

## Credits empty?

1. Switch Goose to **xAI / grok-4.5** ([01](./01-xai-console-setup.md))  
2. Or request top-up of Anthropic credits  
3. Apply [2h cost discipline](./05-cost-optimization-2h.md)
