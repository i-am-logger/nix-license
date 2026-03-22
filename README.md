[![Nix](https://img.shields.io/badge/Nix-flake-5277C3?logo=nixos&logoColor=white)](https://nixos.wiki/wiki/Flakes)
[![Release](https://img.shields.io/github/v/release/i-am-logger/nix-license)](https://github.com/i-am-logger/nix-license/releases)
[![CI](https://github.com/i-am-logger/nix-license/actions/workflows/ci-and-release.yml/badge.svg)](https://github.com/i-am-logger/nix-license/actions/workflows/ci-and-release.yml)
[![SALT](https://img.shields.io/badge/SALT-2649%20licenses-blue)](https://github.com/i-am-logger/salt)

# nix-license

License compliance enforced at build time.

You declare who you are and what you do. nix-license checks every package against [SALT](https://github.com/i-am-logger/salt) (2649 classified licenses). If a package's license conflicts with your declared usage, the build fails.

## The problem

`allowUnfree = true` tells you nothing about what you can actually do with the software. A company that sets it to get NVIDIA drivers has silently allowed CC-BY-NC software that prohibits commercial use. There's no check, no warning, no enforcement.

nix-license replaces this with explicit declarations and build-time enforcement.

## How it works

You declare your usage:

```nix
nix-license = {
  enable = true;

  usage = {
    # Who you are
    type = "commercial";  # personal | commercial | educational | research | government | nonprofit

    # What you do — each matches a SALT restriction key
    commercial-use = true;
    distribution = false;
    modifications = true;
    saas = false;
  };
};
```

nix-license then checks every package's license restrictions against your usage. If a package restricts an activity you declared, the build fails:

```
error: Package 'some-tool' (CC-BY-NC-4.0) prohibits commercial-use.
       Your declared usage includes commercial-use.
```

All fields are required. You must explicitly answer every question.

## Usage examples

```nix
# Personal use — no commercial activity
usage = { type = "personal"; commercial-use = false; distribution = false; modifications = true; saas = false; };

# Company — internal tools
usage = { type = "commercial"; commercial-use = true; distribution = false; modifications = true; saas = false; };

# SaaS company — hosting software as a service
usage = { type = "commercial"; commercial-use = true; distribution = true; modifications = true; saas = true; };

# University — educational and research
usage = { type = "educational"; commercial-use = false; distribution = true; modifications = true; saas = false; };

# Freelancer
usage = { type = "commercial"; commercial-use = true; distribution = false; modifications = true; saas = false; };
```

## Content policy

Per-user content ratings based on [OARS 1.1](https://github.com/hughsie/oars):

```nix
my.users.son.contentPolicy = {
  preset = "child";
  violence-cartoon = "moderate";
};

my.users.parent.contentPolicy = "unrestricted";
```

## Installation

### Standalone NixOS module

```nix
{
  inputs.nix-license.url = "github:i-am-logger/nix-license";

  outputs = { nix-license, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        nix-license.nixosModules.default
        {
          nix-license = {
            enable = true;
            usage = {
              type = "personal";
              commercial-use = false;
              distribution = false;
              modifications = true;
              saas = false;
            };
          };
        }
      ];
    };
  };
}
```

### With mynixos

```nix
imports = [
  nix-license.nixosModules.default
  nix-license.nixosModules.mynixos
];

my.license = {
  enable = true;
  usage = {
    type = "commercial";
    commercial-use = true;
    distribution = false;
    modifications = true;
    saas = false;
  };
};

my.users.logger.contentPolicy = "unrestricted";
```

## Standards

| Standard | What we use |
|----------|-------------|
| [SALT](https://github.com/i-am-logger/salt) | 2649 license classifications with restrictions, obligations, grants, disclaimers |
| [OARS 1.1](https://github.com/hughsie/oars) | Content rating categories derived from upstream RNC schema |
| [OSADL OSLOC](https://github.com/osadl/OSLOC) | Reference for restriction and obligation vocabulary |

## Documentation

| Document | Contents |
|----------|----------|
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Library API, module structure, test coverage |
| [COMPLIANCE.md](docs/COMPLIANCE.md) | Standards mapping (SALT, OARS, OSADL) |
| [Usage-Context RFC](docs/rfc-usage-context-license-model.md) | Usage declaration and license restriction model |
| [Cryptographic Tokens RFC](docs/rfc-cryptographic-license-tokens.md) | Token verification for commercial licenses |
| [Content Policy RFC](docs/rfc-content-policy-model.md) | Content rating entitlements |

## Development

```bash
nix develop       # Dev shell with pre-commit hooks
nix flake check   # Run all checks
nix fmt           # Format all files
```
