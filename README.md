[![Nix](https://img.shields.io/badge/Nix-flake-5277C3?logo=nixos&logoColor=white)](https://nixos.wiki/wiki/Flakes)
[![CI](https://github.com/i-am-logger/nix-license/actions/workflows/ci-and-release.yml/badge.svg)](https://github.com/i-am-logger/nix-license/actions/workflows/ci-and-release.yml)
[![Release](https://img.shields.io/github/v/release/i-am-logger/nix-license?include_prereleases)](https://github.com/i-am-logger/nix-license/releases)
[![SALT](https://img.shields.io/badge/SALT-2649%20licenses-blue)](https://github.com/i-am-logger/salt)

# nix-license

You define your usage — personal, commercial, nonprofit, educational — and nix-license ensures you are in compliance with every package installed on your system. Enforced at build time.

## License terms

Every software license carries terms that determine what you can and cannot do. nix-license evaluates four categories of terms from [SALT](https://github.com/i-am-logger/salt) (2649 classified licenses):

**Restrictions** — what the license prohibits. If your declared usage includes a restricted activity, the package is blocked.

| Restriction | Meaning |
|-------------|---------|
| `commercial-use` | Cannot use for commercial purposes |
| `distribution` | Cannot redistribute to others |
| `modifications` | Cannot modify the source code |
| `saas` | Cannot provide as a hosted or managed service |

**Allowed use** — who the license permits. Some licenses only allow specific types of users (e.g., educational or research). If your type is not in the allowed list, the package is blocked.

**Obligations** — what the license requires you to do. When you distribute or modify software, some licenses require source disclosure, attribution, or using the same license. nix-license warns you about triggered obligations.

**Disclaimers** — what the license does not guarantee (liability, warranty, patent rights, trademark rights). Informational only.

See [SALT TERMS.md](https://github.com/i-am-logger/salt/blob/master/TERMS.md) for the complete vocabulary.

## Usage declaration

You declare two things:

**Who you are** — determines which allowed-use lists you qualify for.

| Type | Description |
|------|-------------|
| `personal` | Individual, non-commercial use |
| `commercial` | For-profit business, freelancer, startup |
| `educational` | School, university, teaching |
| `research` | Academic or scientific research |
| `government` | Government agency |
| `nonprofit` | Registered nonprofit organization |

**What you do** — each activity is checked against license restrictions.

| Activity | What it means |
|----------|---------------|
| `commercial-use` | Using software to generate revenue |
| `distribution` | Shipping software to others (binaries, containers, ISOs) |
| `modifications` | Changing the source code (patches, forks, overlays) |
| `saas` | Running software as a hosted service for others |

All fields are required. You must explicitly answer every question.

## Content policy

Per-user content policies based on [OARS 1.1](https://github.com/hughsie/oars). Administrators set what content categories each user is entitled to. Packages that exceed a user's policy are excluded from their environment.

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
