[![Nix](https://img.shields.io/badge/Nix-flake-5277C3?logo=nixos&logoColor=white)](https://nixos.wiki/wiki/Flakes)
[![CI](https://github.com/i-am-logger/nix-license/actions/workflows/ci-and-release.yml/badge.svg)](https://github.com/i-am-logger/nix-license/actions/workflows/ci-and-release.yml)
[![Release](https://img.shields.io/github/v/release/i-am-logger/nix-license?include_prereleases)](https://github.com/i-am-logger/nix-license/releases)
[![SALT](https://img.shields.io/badge/SALT-2649%20licenses-blue)](https://github.com/i-am-logger/salt)

# nix-license

License compliance enforced at build time.

Today, using software with restrictive licenses is invisible. A company installs a package with a non-commercial license and nothing happens — no warning, no check, no record. The violation is silent until a lawyer sends a letter.

nix-license makes license violations fail the build. You declare who you are and what you do. Every package in your system is checked against [SALT](https://github.com/i-am-logger/salt)'s classification of 2649 software licenses. If a package's license conflicts with your declared usage, the build does not proceed.

There is no separate audit step. No report to review after the fact. No check to remember. Compliance is the build.

## How it works

You answer two questions:

**Who are you?** A personal user, a company, a university, a research lab, a government agency, a nonprofit.

**What do you do with the software?** Use it commercially, distribute it, modify it, provide it as a service.

nix-license checks every package against these answers. A package licensed under CC-BY-NC restricts commercial use — if you declared commercial use, the package is blocked. A package under the Elastic License restricts SaaS — if you provide it as a hosted service, it's blocked.

The check is automatic, covers every package in the system, and runs at build time. You cannot install a package that violates your declared usage.

## What it checks

Each license in [SALT](https://github.com/i-am-logger/salt) has:

- **Restrictions** — what the license prohibits (`commercial-use`, `distribution`, `modifications`, `saas`)
- **Allowed-use** — who the license permits (e.g., only educational or research use)
- **Obligations** — what you must do when distributing (include copyright, disclose source, use same license)

nix-license evaluates your usage against all three. Restrictions block the build. Allowed-use violations block the build. Obligations produce warnings.

## Content policy

nix-license also provides per-user content policies based on [OARS 1.1](https://github.com/hughsie/oars) content ratings. An administrator sets what content categories each user is entitled to. Packages that exceed a user's policy are excluded from their environment.

No PII stored. No birth dates. The admin decides the policy, not the app.

## Documentation

| Document | Audience | Contents |
|----------|----------|----------|
| [USAGE.md](docs/USAGE.md) | Users | Installation, configuration, examples |
| [COMPLIANCE.md](docs/COMPLIANCE.md) | Compliance officers | Standards mapping (SALT, OARS, OSADL, OpenChain) |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Developers | Library API, module structure, test coverage |
| [Usage-Context RFC](docs/rfc-usage-context-license-model.md) | Architects | Usage declaration and license restriction model |
| [Cryptographic Tokens RFC](docs/rfc-cryptographic-license-tokens.md) | Architects | Token verification for commercial license overrides |
| [Content Policy RFC](docs/rfc-content-policy-model.md) | Architects | Content rating entitlements |

## Disclaimer

nix-license is a compliance tool, not legal advice. License evaluations represent a reasonable interpretation of license terms based on [SALT](https://github.com/i-am-logger/salt) classifications. Consult a qualified attorney for legal decisions.

## Development

```bash
nix develop       # Dev shell with pre-commit hooks
nix flake check   # Run all checks
nix fmt           # Format all files
```
