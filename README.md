[![Nix](https://img.shields.io/badge/Nix-flake-5277C3?logo=nixos&logoColor=white)](https://nixos.wiki/wiki/Flakes)
[![CI](https://github.com/i-am-logger/nix-license/actions/workflows/ci-and-release.yml/badge.svg)](https://github.com/i-am-logger/nix-license/actions/workflows/ci-and-release.yml)
[![Release](https://img.shields.io/github/v/release/i-am-logger/nix-license?include_prereleases)](https://github.com/i-am-logger/nix-license/releases)
[![SALT](https://img.shields.io/badge/SALT-2649%20licenses-blue)](https://github.com/i-am-logger/salt)

# nix-license

You define your usage — personal, commercial, nonprofit, educational, etc. — and nix-license ensures you are in compliance with every package installed on your system.

License data from [SALT](https://github.com/i-am-logger/salt) (2649 classified licenses). Content policies from [OARS 1.1](https://github.com/hughsie/oars). Enforced at build time.

## Documentation

| Document | For | Contents |
|----------|-----|----------|
| [USAGE.md](docs/USAGE.md) | Engineers | Installation, configuration, examples |
| [COMPLIANCE.md](docs/COMPLIANCE.md) | Compliance | Standards (SALT, OARS, OSADL, OpenChain) |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Developers | Library API, tests, module structure |

## Disclaimer

Not legal advice. Consult an attorney for legal decisions.

## Development

```bash
nix develop       # Dev shell
nix flake check   # Run all checks
nix fmt           # Format
```
