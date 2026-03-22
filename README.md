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
- [x] **Content policy** — per-user content entitlements based on [OARS 1.1](https://github.com/hughsie/oars)
- [x] **125,000+ behavioral assertions** — every license × every usage context verified on every commit
- [ ] **OpenChain ISO/IEC 5230** — tooling toward organizational self-certification
- [x] **Commitments** — declare which obligations you can fulfill; copyleft blocked if you can't
- [x] **Assurances** — require patent grants, liability coverage, warranty from licenses
- [x] **Cryptographic license tokens** — GPG/YubiKey-signed commercial license verification
- [ ] **SBOM generation** *(commercial)* — software bill of materials with full license classification

## Domain model

Every license carries terms. Every user declares their context. nix-license evaluates one against the other.

**License side** ([SALT](https://github.com/i-am-logger/salt) — 2649 classified licenses):

| Term | What it is | Example |
|------|-----------|---------|
| Restrictions | What the license prohibits | `commercial-use`, `distribution`, `modifications`, `saas` |
| Allowed-use | Who the license permits | `educational`, `research` |
| Obligations | What the license requires you to do | `disclose-source`, `same-license`, `include-copyright` |
| Disclaimers | What the license doesn't guarantee | `liability`, `warranty`, `patent-use`, `trademark-use` |

**User side** (your NixOS config):

| Term | What it is | Example |
|------|-----------|---------|
| Usage (type) | Who you are | `personal`, `commercial`, `nonprofit`, `educational` |
| Usage (activities) | What you do | `commercial-use`, `distribution`, `modifications`, `saas` |
| Commitments | Which obligations you can fulfill | `same-license = false` (can't open-source) |
| Assurances | What guarantees you require | `patent-grant = true` (require patent rights) |

**Evaluation** — four checks, all must pass:

| License | User | Blocks when |
|---------|------|-------------|
| Restrictions | Usage (activities) | Activity is restricted |
| Allowed-use | Usage (type) | Type not in allowed list |
| Obligations | Commitments | Obligation triggers and user can't commit |
| Disclaimers | Assurances | License disclaims what user requires |

See [SALT TERMS.md](https://github.com/i-am-logger/salt/blob/master/TERMS.md) for the complete vocabulary.

## OpenChain ISO/IEC 5230

[OpenChain ISO/IEC 5230](https://openchainproject.org/license-compliance) certifies organizational compliance programs. nix-license provides build-time enforcement that supports such programs:

| OpenChain requirement | nix-license role |
|---|---|
| Written open source policy | Usage declaration in NixOS config is the policy |
| Process to review licenses | Every package's license is evaluated against declared usage at build time |
| License identification | All 289 nixpkgs licenses mapped to [SALT](https://github.com/i-am-logger/salt) classifications |
| Compliance artifacts | Triggered obligations are tracked per-package |

## Content policy

Per-user content policies based on [OARS 1.1](https://github.com/hughsie/oars). Administrators set what content categories each user is entitled to. Packages that exceed a user's policy are excluded from their environment.

## Documentation

- [COMPLIANCE.md](docs/COMPLIANCE.md) — Standards (SALT, OARS, OSADL, OpenChain)
- [ARCHITECTURE.md](docs/ARCHITECTURE.md) — Library API, tests, module structure
- [USAGE.md](docs/USAGE.md) — Installation, configuration, examples

## Verification

Every license evaluation is verified at build time via `nix flake check`:

| Test | Scope | What it verifies |
|------|-------|-----------------|
| Restriction enforcement | 2649 × 16 | Active restriction + matching usage activity → blocked |
| Allowed-use enforcement | 2649 × 6 | User type in/not in allowed-use list → allowed/blocked |
| Obligation triggers | 2649 × 16 | Obligations fire exactly when their trigger keys match usage |
| Monotonicity | 2649 × 5 | Adding a usage flag never removes a conflict |
| No-restriction allowed | unrestricted × 16 | No restrictions and no allowed-use → always allowed |
| Empty usage safe | 2649 | Empty usage declaration → no restriction conflicts |
| nixpkgs coverage | 289/289 | Every nixpkgs license maps to a SALT classification |

Over 125,000 behavioral assertions across all 2649 SALT licenses, run on every commit.

## Disclaimer

nix-license is a compliance tool, not legal advice. License classifications are based on [SALT](https://github.com/i-am-logger/salt). Consult a qualified attorney for legal decisions.

## Development

```bash
nix develop       # Dev shell
nix flake check   # Run all checks
nix fmt           # Format
```
