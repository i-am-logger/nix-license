[![NixOS](https://img.shields.io/badge/NixOS-5277C3?logo=nixos&logoColor=white)](https://nixos.org)
[![Release](https://img.shields.io/github/v/release/i-am-logger/nix-license)](https://github.com/i-am-logger/nix-license/releases)
[![CI and Release](https://github.com/i-am-logger/nix-license/actions/workflows/ci-and-release.yml/badge.svg)](https://github.com/i-am-logger/nix-license/actions/workflows/ci-and-release.yml)
[![SALT](https://img.shields.io/badge/SALT-2649%20licenses-blue)](https://github.com/i-am-logger/salt)

[![License: CC BY-NC-SA 4.0](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-sa/4.0/)

# nix-license

A NixOS module that checks every package's license against your declared usage at build time.

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
            enforcement = "enforce";

            usage = {
              type = "commercial";
              commercial-use = true;
              distribution = false;
              modifications = true;
              saas = false;
            };

            # Can't open-source our product → blocks GPL, AGPL
            commitments.same-license = false;
            commitments.disclose-source = false;
          };
        }
      ];
    };
  };
}
```

With this config, any package with a non-commercial license (CC-BY-NC), a SaaS restriction (Elastic, SSPL), or a copyleft obligation you can't fulfill (GPL) fails at eval time. Permissive licenses (MIT, Apache, BSD) pass.

## How it works

Every nixpkgs license is mapped to [SALT](https://github.com/i-am-logger/salt) (2649 classified licenses). When nixpkgs evaluates a package, `allowUnfreePredicate` runs four checks:

| License has | User declared | Blocks when |
|-------------|---------------|-------------|
| Restrictions | Usage (activities) | Activity is restricted |
| Allowed-use | Usage (type) | Type not in allowed list |
| Obligations | Commitments | Obligation triggers and user can't fulfill |
| Disclaimers | Assurances | License disclaims what user requires |

`enforcement = "warn"` logs conflicts via `builtins.trace` and allows the package. `enforcement = "enforce"` blocks the build.

## Usage

**Who you are** (`usage.type`): `personal`, `commercial`, `educational`, `research`, `government`, `nonprofit`

**What you do** (checked against license restrictions):

| Flag | When to set true |
|------|-----------------|
| `commercial-use` | Any for-profit activity |
| `distribution` | Shipping binaries, containers, ISOs to others |
| `modifications` | Patching, forking, applying overlays |
| `saas` | Running software as a hosted service |

**Commitments** — which obligations you can fulfill (default: all true):

| Key | What it means | Set false to block |
|-----|--------------|-------------------|
| `same-license` | Distribute under same license | GPL, AGPL, copyleft |
| `disclose-source` | Make source available | GPL on distribution |
| `network-use-disclose` | Share source for network use | AGPL on SaaS |
| `include-copyright` | Include copyright notices | Most licenses on distribution |
| `document-changes` | Document modifications | GPL, Apache on distribution |

**Assurances** — require guarantees from licenses (default: all false):

| Key | Set true to block licenses that disclaim |
|-----|----------------------------------------|
| `patent-grant` | Patent rights |
| `liability-coverage` | Liability |
| `warranty` | Warranty |

All usage fields are required. No defaults — you must explicitly declare your context.

## Content policy

Per-user content entitlements based on [OARS 1.1](https://github.com/hughsie/oars). Resolved policies are written to `/etc/nix-license/content-policy/` as immutable Nix store symlinks for apps to query at runtime. See [USAGE.md](docs/USAGE.md).

## Commercial licensing

Commercial use in enforce mode requires a GPG-signed token. Vendor packages can use any algorithm via openssl. See [COMPLIANCE.md](docs/COMPLIANCE.md).

## Documentation

- [USAGE.md](docs/USAGE.md) — Installation, configuration, examples
- [ARCHITECTURE.md](docs/ARCHITECTURE.md) — Domain model, library API, module structure
- [COMPLIANCE.md](docs/COMPLIANCE.md) — Standards (SALT, OARS, OpenChain)

## Testing

Every license (2649) is evaluated and tested against every usage context (16 activity combinations × 6 user types × 7 commitment keys × 3 assurance keys), producing over 200,000 individual pass/fail checks per `nix flake check`.

```bash
nix flake check   # Run all checks
nix develop       # Dev shell
nix fmt           # Format
```
