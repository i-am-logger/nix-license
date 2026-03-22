[![Nix](https://img.shields.io/badge/Nix-flake-5277C3?logo=nixos&logoColor=white)](https://nixos.wiki/wiki/Flakes)
[![CI](https://github.com/i-am-logger/nix-license/actions/workflows/ci-and-release.yml/badge.svg)](https://github.com/i-am-logger/nix-license/actions/workflows/ci-and-release.yml)
[![Release](https://img.shields.io/github/v/release/i-am-logger/nix-license?include_prereleases)](https://github.com/i-am-logger/nix-license/releases)
[![SALT](https://img.shields.io/badge/SALT-2649%20licenses-blue)](https://github.com/i-am-logger/salt)

# nix-license

A NixOS module that checks package licenses against your declared usage at build time. Uses [SALT](https://github.com/i-am-logger/salt) (2649 classified licenses).

You declare who you are and what you do. If a package's license conflicts with your usage, the build fails.

```nix
nix-license = {
  enable = true;
  usage = {
    type = "commercial";
    commercial-use = true;
    distribution = false;
    modifications = true;
    saas = false;
  };
};
```

Also provides per-user content policies based on [OARS 1.1](https://github.com/hughsie/oars).

## Documentation

| Document | Contents |
|----------|----------|
| [USAGE.md](docs/USAGE.md) | Installation, configuration, examples |
| [COMPLIANCE.md](docs/COMPLIANCE.md) | Standards (SALT, OARS, OSADL, OpenChain) |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Library API, tests, module structure |

## Disclaimer

Not legal advice. See [SALT](https://github.com/i-am-logger/salt) for license classification details.

## Development

```bash
nix develop       # Dev shell
nix flake check   # Run all checks
nix fmt           # Format
```
