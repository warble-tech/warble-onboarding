# Security Policy

## Reporting a vulnerability

**Please don't open public issues for security problems.**

Report them privately through GitHub's
[private vulnerability reporting](https://github.com/warble-tech/warble-onboarding/security/advisories/new)
for this repository.

Please include:
- the affected file(s) or script(s) and the commit SHA,
- steps to reproduce, and the impact you expect,
- any suggested fix.

We aim to acknowledge reports within 5 business days.

## Scope

This repository contains onboarding shell/PowerShell scripts and documentation.
Relevant reports include:
- scripts that download or execute content insecurely (e.g. an unverified or hijackable URL),
- a secret or credential accidentally committed to the repo,
- documentation that recommends an unsafe configuration.

Vulnerabilities in third-party tools the scripts install (goose, BrowserOS, Claude Code,
Antigravity, kubectl, etc.) should go to those projects directly.

## Secrets

If you find what looks like a live credential in this repository or its history,
report it privately using the link above, and don't use it.
