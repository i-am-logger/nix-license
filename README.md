[![Nix](https://img.shields.io/badge/Nix-flake-5277C3?logo=nixos&logoColor=white)](https://nixos.wiki/wiki/Flakes)
[![CI](https://github.com/i-am-logger/nix-license/actions/workflows/ci-and-release.yml/badge.svg)](https://github.com/i-am-logger/nix-license/actions/workflows/ci-and-release.yml)
[![Release](https://img.shields.io/github/v/release/i-am-logger/nix-license?include_prereleases)](https://github.com/i-am-logger/nix-license/releases)
[![SALT](https://img.shields.io/badge/SALT-2649%20licenses-blue)](https://github.com/i-am-logger/salt)

# nix-license

You define your usage — personal, commercial, nonprofit, educational — and nix-license ensures you are in compliance with every package installed on your system. Enforced at build time.

## Features

- [x] **License enforcement** — restrictions, allowed-use, and obligations evaluated per-package at build time
- [x] **2649 classified licenses** — powered by [SALT](https://github.com/i-am-logger/salt) (restrictions, obligations, grants, disclaimers)
- [x] **Full nixpkgs coverage** — all 289 nixpkgs licenses mapped to SALT
- [x] **Usage declaration** — explicit type (who) + activity flags (what), no implicit defaults
- [x] **Commitments** — declare which obligations you can fulfill; copyleft blocked if you can't
- [x] **Assurances** — require patent grants, liability coverage, warranty from licenses
- [x] **Content policy** — per-user content entitlements based on [OARS 1.1](https://github.com/hughsie/oars)
- [x] **Cryptographic license tokens** — GPG/YubiKey (nix-license) + algorithm-agnostic via openssl (vendors)
- [x] **200,000+ behavioral assertions** — every license × every usage context verified on every commit
- [ ] **OpenChain ISO/IEC 5230** — tooling toward organizational self-certification ([#6](https://github.com/i-am-logger/nix-license/issues/6))
- [ ] **SBOM generation** *(commercial)* — software bill of materials with full license classification ([#7](https://github.com/i-am-logger/nix-license/issues/7))

## Documentation

- [ARCHITECTURE.md](docs/ARCHITECTURE.md) — Domain model, library API, tests, module structure
- [COMPLIANCE.md](docs/COMPLIANCE.md) — Standards (SALT, OARS, OSADL, OpenChain)
- [USAGE.md](docs/USAGE.md) — Installation, configuration, examples

## Disclaimer

nix-license is a compliance tool, not legal advice. License classifications are based on [SALT](https://github.com/i-am-logger/salt). Consult a qualified attorney for legal decisions.

## Development

```bash
nix develop       # Dev shell
nix flake check   # Run all checks
nix fmt           # Format
```
