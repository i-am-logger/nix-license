[![Nix](https://img.shields.io/badge/Nix-flake-5277C3?logo=nixos&logoColor=white)](https://nixos.wiki/wiki/Flakes)
[![CI](https://github.com/i-am-logger/nix-license/actions/workflows/ci-and-release.yml/badge.svg)](https://github.com/i-am-logger/nix-license/actions/workflows/ci-and-release.yml)
[![Release](https://img.shields.io/github/v/release/i-am-logger/nix-license?include_prereleases)](https://github.com/i-am-logger/nix-license/releases)
[![SALT](https://img.shields.io/badge/SALT-2649%20licenses-blue)](https://github.com/i-am-logger/salt)

# nix-license

You define your usage — personal, commercial, nonprofit, educational — and nix-license ensures you are in compliance with every package installed on your system. Enforced at build time.

## How it works

Every software license has terms — what it allows, what it requires, what it prohibits. nix-license uses [SALT](https://github.com/i-am-logger/salt), a classification of 2649 software licenses, to know what each license permits and restricts.

You declare two things about your organization:

**Who you are** — your usage type determines which licenses apply to you. An educational institution can use academic-only software that a commercial company cannot.

| Type | Description |
|------|-------------|
| `personal` | Individual, non-commercial use |
| `commercial` | For-profit business, freelancer, startup |
| `educational` | School, university, teaching |
| `research` | Academic or scientific research |
| `government` | Government agency |
| `nonprofit` | Registered nonprofit organization |

**What you do with the software** — each activity is checked against the license's restrictions. If a license prohibits an activity you declared, the package is blocked.

| Activity | What it means |
|----------|---------------|
| `commercial-use` | Using software to generate revenue |
| `distribution` | Shipping software to others (binaries, containers, ISOs) |
| `modifications` | Changing the source code (patches, forks, overlays) |
| `saas` | Running software as a hosted service for others |

## What gets checked

For each package on the system, nix-license evaluates:

- **Restrictions** — does the license prohibit any activity you declared? A CC-BY-NC license restricts `commercial-use`. If you declared `commercial-use = true`, the package is blocked.
- **Allowed use** — does the license limit who can use it? An academic-only license permits `educational` and `research` users. If your type is `commercial`, the package is blocked.
- **Obligations** — does the license require something when you distribute or modify? GPL requires source disclosure when distributing. nix-license warns you about these obligations.

## Content policy

nix-license also supports per-user content policies based on [OARS 1.1](https://github.com/hughsie/oars) content ratings. Administrators set what content categories each user is entitled to — violence, social features, in-app purchases, etc. Packages that exceed a user's policy are excluded from their environment.

## Documentation

- [COMPLIANCE.md](docs/COMPLIANCE.md) — Standards (SALT, OARS, OSADL, OpenChain)
- [ARCHITECTURE.md](docs/ARCHITECTURE.md) — Library API, tests, module structure
- [USAGE.md](docs/USAGE.md) — Installation, configuration, examples

## Disclaimer

nix-license is a compliance tool, not legal advice. License classifications are based on [SALT](https://github.com/i-am-logger/salt). Consult a qualified attorney for legal decisions.

## Development

```bash
nix develop       # Dev shell
nix flake check   # Run all checks
nix fmt           # Format
```
