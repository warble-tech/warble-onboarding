# Managing AI agents at Warble

This applies to Goose, Claude Code, Google Antigravity (`agy`), BrowserOS, and Grok Build.
Pair it with the [2h/day cost guide](./05-cost-optimization-2h.md) and each repo's root `AGENTS.md`.

## 1. One agent per task, one tree per agent

- Never run two agents on the same uncommitted working tree. You get double edits and a double bill.
- To run agents in parallel, give each its own worktree:

  ```bash
  git worktree add ../<repo>-<task> -b agent/<tool>/<task>
  # e.g. git worktree add ../warble-api-helm-lint -b agent/goose/fix-helm-lint
  git worktree remove ../<repo>-<task>   # when merged
  ```

- Branch naming: `agent/<tool>/<short-task>`.

## 2. Permission modes: pick the least autonomous mode that works

| Tool | Warble default | How to set it |
|------|----------------|---------------|
| Goose | `smart_approve` (**upstream default is `auto`**, fully autonomous) | `export GOOSE_MODE=smart_approve`, or `/mode smart_approve` mid-session |
| Goose, read-only analysis | `chat` | `GOOSE_MODE=chat` |
| Antigravity | **Default** preset (terminal sandbox) or **Request Review**; never Turbo with prod creds | Settings → General → Permission Settings |
| Claude Code | default (asks before edits/commands) | don't use permission-skipping flags on laptops |
| BrowserOS | a dedicated profile, logged in only to what the task needs | BrowserOS profiles / settings |

References:
[Goose permission modes](https://goose-docs.ai/docs/guides/managing-tools/goose-permissions) ·
[Goose tool permissions](https://goose-docs.ai/docs/guides/managing-tools/tool-permissions) ·
[Antigravity permissions](https://antigravity.google/docs/permissions) ·
[Antigravity terminal sandbox](https://antigravity.google/docs/sandbox)

## 3. Guardrails in your shell (`~/.zshrc` or a direnv `.envrc`)

```bash
export GOOSE_MODE=smart_approve        # upstream default: auto
export GOOSE_MAX_TURNS=50              # upstream default: 1000 — stops runaway tool loops
export GOOSE_TELEMETRY_ENABLED=false
export CONTEXT_FILE_NAMES='["AGENTS.md", ".goosehints"]'   # Goose's default, made explicit
```

All of these are documented in [Goose environment variables](https://goose-docs.ai/docs/guides/environment-variables).

## 4. Context files: one source of truth

- Every repo gets a short root **`AGENTS.md`** with build/test commands, forbidden actions, and owners.
  Keep it under ~60 lines, because it's sent with **every** request.
- **Goose** reads `AGENTS.md` and `.goosehints` (global file: `~/.config/goose/.goosehints`).
  [Docs](https://goose-docs.ai/docs/guides/context-engineering/using-goosehints).
- **Antigravity** reads `AGENTS.md` / `GEMINI.md` / `.agents/rules/*.md` (global file: `~/.gemini/AGENTS.md`).
  [Docs](https://antigravity.google/docs/rules).
- **Claude Code** reads `CLAUDE.md`. Make it a single line, "Follow AGENTS.md", so the rules don't drift apart.

## 5. Secrets and blast radius

- Don't keep a **prod** kubeconfig context or prod `gcloud` project active while an agent session is open.
  Switch first: `kubectx <dev-context>` and `gcloud config set project <dev-project>`.
- Give MCP servers fine-scoped tokens: repo-scoped GitHub tokens, read-only where possible.
- Never paste `.env` contents, Secret Manager values, or Cloudflare tokens into prompts.
- If a key ever appears in an agent transcript or log, rotate it.

## 6. MCP hygiene

- Enable MCP servers per task, not globally. Every server adds tool schemas (tokens) and attack surface.
- Treat web and browser content as untrusted because of prompt injection. Goose has built-in
  [prompt-injection detection](https://goose-docs.ai/docs/guides/security/prompt-injection-detection).
- Point Kubernetes MCP servers at **dev** clusters only.

## 7. Session hygiene and cost

- Start a fresh session per task. Goose auto-compacts at 80% context (`GOOSE_AUTO_COMPACT_THRESHOLD`),
  but start a new session past ~150k tokens anyway, because Grok's long-context pricing kicks in above 200k.
- No unattended overnight runs. Anything scheduled (`goose schedule`, Antigravity scheduled or background
  agents, BrowserOS scheduled tasks) needs a named owner and a spend cap.
- At the end of each session: review `git diff`, run the tests, and write the commit message yourself.

## 8. Review before merge

- Run `goose review` (or your agent's diff review) on the branch, then get a normal human PR review.
- Agents never approve or merge their own PRs.
- Label agent-authored PRs `agent-assisted` so reviewers know to look harder.

## Quick checklist

- [ ] Clean `git status`, own branch or worktree
- [ ] Least-autonomy mode set (`GOOSE_MODE`, Antigravity preset)
- [ ] Dev kube context / GCP project active, not prod
- [ ] Only the MCP servers this task needs
- [ ] Session closed, diff reviewed, tests run, usage checked

Back: [AI onboarding index](./README.md)
