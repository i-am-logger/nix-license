[![Nix](https://img.shields.io/badge/Nix-flake-5277C3?logo=nixos&logoColor=white)](https://nixos.wiki/wiki/Flakes)
[![CI](https://github.com/i-am-logger/nix-license/actions/workflows/ci-and-release.yml/badge.svg)](https://github.com/i-am-logger/nix-license/actions/workflows/ci-and-release.yml)
[![Release](https://img.shields.io/github/v/release/i-am-logger/nix-license?include_prereleases)](https://github.com/i-am-logger/nix-license/releases)
[![SALT](https://img.shields.io/badge/SALT-2649%20licenses-blue)](https://github.com/i-am-logger/salt)

# nix-license

Software systems are built from hundreds of packages, each with its own license. Some licenses prohibit commercial use. Some prohibit redistribution. Some prohibit running the software as a hosted service. Most organizations have no way to know which of these restrictions apply to the software they use — until they're in violation.

nix-license solves this by checking every package's license against your organization's declared usage at build time. If a conflict exists, the build does not succeed. You cannot deploy software that violates your license obligations.

It works by combining two things:

1. **[SALT](https://github.com/i-am-logger/salt)** — a classification of 2649 software licenses into what they permit, what they require, what they prohibit, and what they disclaim
2. **A usage declaration** — your organization states who it is (company, university, nonprofit) and what it does with the software (commercial use, distribution, modification, SaaS)

The system also supports per-user content policies for environments where administrators need to control what software is available to specific users (families, schools, shared workstations).

## Documentation

| Document | For | Contents |
|----------|-----|----------|
| [USAGE.md](docs/USAGE.md) | Engineers | How to install, configure, and use nix-license |
| [COMPLIANCE.md](docs/COMPLIANCE.md) | Compliance | Standards alignment (SALT, OARS, OSADL, OpenChain) |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Developers | Library API, module structure, test coverage |

## Disclaimer

nix-license is a compliance tool, not legal advice. License classifications are based on [SALT](https://github.com/i-am-logger/salt). Consult a qualified attorney for legal decisions.

## Development

```bash
nix develop       # Dev shell
nix flake check   # Run all checks
nix fmt           # Format
```
