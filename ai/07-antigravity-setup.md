# Google Antigravity (Warble)

Antigravity is Google's agentic development platform: **Antigravity 2.0** (the desktop
agent manager), the **Antigravity IDE**, and the **Antigravity CLI (`agy`)**.

It's **optional** at Warble. Goose and Claude Code stay the default agents, and credit routing
is unchanged (see [05 — Credit routing](./05-cost-optimization-2h.md#credit-routing-warble-policy)).
Antigravity bills **Google AI credits / plan quota**, not our Anthropic or xAI keys.

## Official links

| | |
|--|--|
| Home | https://antigravity.google |
| Download (desktop) | https://antigravity.google/download |
| Getting started | https://antigravity.google/docs/getting-started |
| CLI install & auth | https://antigravity.google/docs/cli/install |
| CLI best practices | https://antigravity.google/docs/cli/best-practices |
| Permissions | https://antigravity.google/docs/permissions |
| Terminal sandbox | https://antigravity.google/docs/sandbox |
| Rules (`AGENTS.md`, `.agents/rules/`) | https://antigravity.google/docs/rules |
| Agent skills | https://antigravity.google/docs/skills |
| MCP | https://antigravity.google/docs/mcp |
| AI credits (CLI) | https://antigravity.google/docs/cli/credits |
| Plans & pricing | https://antigravity.google/pricing |

## Install

The installers don't install Antigravity unless you ask for it:

| OS | Desktop app | CLI (`agy`) |
|----|-------------|-------------|
| macOS | `brew install --cask antigravity` | `curl -fsSL https://antigravity.google/cli/install.sh \| bash` |
| Linux | tarball from https://antigravity.google/download?os=linux | same `install.sh` (installs to `~/.local/bin/agy`) |
| Windows | installer from https://antigravity.google/download | `irm https://antigravity.google/cli/install.ps1 \| iex` |

The onboarding scripts can do it for you:

```bash
WARBLE_INSTALL_ANTIGRAVITY=1 bash linux/install-devtools.sh   # agy CLI
WARBLE_INSTALL_ANTIGRAVITY=1 bash mac/install-devtools.sh     # desktop cask + agy CLI
# Windows: answer "y" to "Google Antigravity CLI (agy)" in windows/setup.ps1
```

Verify and update:

```bash
agy --version
agy update
```

**Sign-in:** the first run opens your browser for Google sign-in (a personal account, or **Business account**
for Gemini Enterprise). Over SSH, the CLI uses a remote OAuth flow instead. The session token is stored in your
OS keyring.

## Warble defaults

| Setting | Warble value | Why |
|---------|--------------|-----|
| Permission preset | **Default** (sandbox on), or **Request Review** | Default runs terminal commands in a sandbox: workspace + temp dirs only, no network, `~/.ssh` and `.env` blocked |
| **Turbo** preset | **Not on laptops that hold prod credentials** | Turbo means unrestricted commands, full filesystem access, and MCP/web allowed |
| `--dangerously-skip-permissions` | Throwaway VMs / CI sandboxes only | Skips every approval |
| Project scope | One repo per Antigravity project | Agents only see folders in the project |
| Rules | Repo `AGENTS.md` (shared with Goose) + `.agents/rules/*.md` | Antigravity loads `AGENTS.md` / `GEMINI.md` / `.agents/rules/` automatically |
| MCP servers | Only what the task needs (Settings → Customizations → Installed MCP Servers) | Fewer tools means less risk and fewer tokens |

Set the preset under **Settings → General → Permission Settings**. You can override it per project under
**Settings → Projects**. Windows still uses Antigravity's older permission system, so prefer
**Request Review** there.

## Cost and coexistence

- Check quota with `/usage` and `/credits` in the CLI.
- Count Antigravity time inside your [~2h/day agent budget](./05-cost-optimization-2h.md).
- **Never run Antigravity and Goose or Claude Code on the same uncommitted tree.** Use a separate branch or
  `git worktree`.
- No unattended scheduled or background agents without an owner and a quota check.

Back: [AI onboarding index](./README.md)
