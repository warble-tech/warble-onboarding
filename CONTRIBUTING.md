# Contributing to warble-onboarding

Thanks for helping improve the Warble onboarding guide!

## How to contribute
1. Fork the repo and create a branch: `fix/<topic>` or `feat/<topic>`.
2. Make your change. Keep each PR focused on one topic.
3. Run the checks below.
4. Open a pull request that describes what changed and how you tested it.

## Checks
- Shell: `bash -n <file>` and `shellcheck -S warning linux/*.sh mac/*.sh`
- PowerShell: parse cleanly (e.g. `Invoke-ScriptAnalyzer` / PSScriptAnalyzer)
- Docs: every link must resolve. Use official vendor URLs only.
- Secrets: CI runs gitleaks. Never commit API keys, tokens, `.env` files or kubeconfigs.
  Examples use placeholders like `xai-...` / `sk-ant-...`.

## Conventions
- When you add a tool, add it to every OS installer it applies to, plus `README.md` and `ai/README.md`.
- Docker/kind stay **off by default**.
- Keep `ai/` docs numbered (`NN-topic.md`) and update the index in `ai/README.md`.
- Using AI agents to write a contribution is fine. Please read [AGENTS.md](./AGENTS.md)
  and review the diff yourself before you open the PR.

## Trademarks
Third-party names and logos (e.g. goose™) belong to their owners. Follow their
trademark policies, and don't imply endorsement.

By contributing, you agree that your contributions are licensed under the repository's [LICENSE](./LICENSE).
