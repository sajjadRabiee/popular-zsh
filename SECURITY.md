# Security policy for popular.zsh

## Supported versions

Security fixes are applied to the default branch on GitHub (`main`). Users should install from that branch or run `pupdate` from a trusted source (see **Threat model** below).

## Reporting a vulnerability

If you believe you have found a security vulnerability:

1. **Do not** open a public GitHub issue with exploit details before there is a fix users can apply.
2. Use **GitHub private vulnerability reporting** for this repository if it is enabled (Repository → **Security** → **Report a vulnerability**), or contact the maintainers through a private channel they publish on the repo or profile.

Include:

- A short description of the issue and its impact.
- Steps to reproduce (commands, file snippets redacted as needed).
- Your assessment of severity, if you have one.

We aim to acknowledge reports in a reasonable timeframe and coordinate disclosure after a fix is available.

## Threat model and safe use

Understanding how the tool works helps you use it safely:

### Stored commands run with full shell power

The `p` command builds a string from your saved template and arguments, substitutes secrets, then runs it with **`eval`**. That is intentional: shortcuts can contain arbitrary shell syntax. Anyone who can **modify your commands file** or trick you into **`pimport`** of a malicious export can run code as you.

**Mitigations:** Restrict access to `POPULAR_COMMANDS_FILE`, only import files you trust, and review imports before using them in sensitive environments.

### Secrets are encrypted at rest (AES-256-CBC)

Secret values are encrypted with **AES-256-CBC** (openssl, PBKDF2) before being written to `POPULAR_SECRETS_FILE`. A master password is prompted on first use in each shell session and cached in the shell's memory (never written to disk). The file is still chmod `600`.

**Limitations:** Security depends on the strength of your master password and the integrity of your `openssl` installation. AES-CBC with PBKDF2 is not hardware-backed (no TPM/Secure Enclave). If an attacker can run code as you they can intercept the cached key from process memory or hook into your shell session.

**Mitigations:** Use a strong, unique master password; lock the session with `plock` when stepping away; combine with full-disk encryption and a locked user account.

**Migration:** If you have a v1 secrets file (plain-text values, no `# popular.zsh secrets v2` header), run `psecret-migrate` once to re-encrypt it. A `.bak` copy is kept until you remove it.

### Remote install and `pupdate`

[`install.sh`](install.sh) and **`pupdate`** download scripts over **HTTPS** from `POPULAR_REPO_BASE` (default: GitHub raw content). You are trusting that URL and TLS.

**Mitigations:** Prefer cloning from GitHub and sourcing locally if you want to inspect code before running it. Only set `POPULAR_REPO_BASE` to origins you fully trust.

### Curl-to-shell installer

The README documents `curl … | zsh`. That pattern runs whatever the remote URL returns; only use it if you trust the hosting account and path.

**Mitigations:** Download `install.sh`, read it, then run it; or clone the repo and `source` manually.

## Security-related contributions

Improvements that harden defaults without breaking legitimate workflows (clearer warnings, safer parsing where applicable, documentation) are welcome. Large behavior changes may need discussion in an issue first.
