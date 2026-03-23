[![NixOS](https://img.shields.io/badge/NixOS-5277C3?logo=nixos&logoColor=white)](https://nixos.org)
[![CI and Release](https://github.com/i-am-logger/nix-license/actions/workflows/ci-and-release.yml/badge.svg)](https://github.com/i-am-logger/nix-license/actions/workflows/ci-and-release.yml)

[![Release](https://img.shields.io/github/v/release/i-am-logger/nix-license)](https://github.com/i-am-logger/nix-license/releases)
[![SALT](https://img.shields.io/badge/SALT-2649%20licenses-blue)](https://github.com/i-am-logger/salt)

[![License: CC BY-NC-SA 4.0](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-sa/4.0/)

# nix-license

A NixOS module that checks every package's license against your declared usage at build time. Replaces `allowUnfree`.

### Personal user — FOSS-only with NVIDIA exception

```nix
nix-license = {
  enable = true;
  usage = {
    type = "personal";
    commercial-use = false;
    distribution = false;
    modifications = true;
    saas = false;
  };

  # FOSS only — block closed-source packages
  assurances.source-available = {
    required = true;
    exceptions = [ "nvidia-x11" ];  # accept NVIDIA's proprietary driver
  };
};
```

No more `allowUnfree = true`. Closed-source packages are blocked. NVIDIA is explicitly whitelisted. CC-BY-NC, Elastic, SSPL — allowed because they have source.

### Commercial company — proprietary product

```nix
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
  commitments.same-license = {
    fulfilled = false;
    exceptions = [ "libfoo" ];  # except this one we already open-sourced
  };
  commitments.disclose-source.fulfilled = false;

  # Require patent grants, except for legacy code
  assurances.patent-grant = {
    required = true;
    exceptions = [ "legacy-lib" ];
  };

  # Commercial licenses
  licenses."nix-license" = {
    license = "commercial";
    tokenFile = ./secrets/nix-license.token;
  };
  licenses."vendor-package" = {
    license = "commercial";
    tokenFile = ./secrets/vendor-package.token;
  };
};
```

GPL is blocked — except `libfoo` which you've already open-sourced. Patent grants are required — except `legacy-lib`. Non-commercial licenses (CC-BY-NC) and SaaS restrictions (Elastic, SSPL) fail at eval time. Permissive licenses (MIT, Apache, BSD) pass.

**No more `allowUnfree`.** nixpkgs conflates "closed source" with "has restrictions" in a single boolean. nix-license replaces it with the actual questions: what's your usage, what can you commit to, what guarantees do you need.

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

**Commitments** — which obligations you can fulfill (default: all `fulfilled = true`):

| Key | What it means | Set `fulfilled = false` to block |
|-----|--------------|--------------------------------|
| `same-license` | Distribute under same license | GPL, AGPL, copyleft |
| `disclose-source` | Make source available | GPL on distribution |
| `network-use-disclose` | Share source for network use | AGPL on SaaS |
| `include-copyright` | Include copyright notices | Most licenses on distribution |
| `document-changes` | Document modifications | GPL, Apache on distribution |

Each commitment supports `exceptions` — package names exempt from that commitment.

**Assurances** — require guarantees from licenses (default: all `required = false`):

| Key | Set `required = true` to block licenses that disclaim |
|-----|------------------------------------------------------|
| `source-available` | Source code (blocks closed-source binaries) |
| `patent-grant` | Patent rights |
| `liability-coverage` | Liability |
| `warranty` | Warranty |

Each assurance supports `exceptions` — a list of package names exempt from that requirement.

All usage fields are required. No defaults — you must explicitly declare your context.

## Content policy

Per-user content entitlements based on [OARS 1.1](https://github.com/hughsie/oars). Resolved policies are written to `/etc/nix-license/content-policy/` as immutable Nix store symlinks for apps to query at runtime. See [USAGE.md](docs/USAGE.md).

## Commercial licensing

Commercial use in enforce mode requires `licenses."nix-license"` with a valid token. Vendor packages use the same pattern — `licenses."package-name"` with a signed token overrides a license conflict. nix-license tokens are GPG/YubiKey-signed; vendor tokens use any algorithm (Ed25519, RSA, ECDSA) via openssl. See [USAGE.md](docs/USAGE.md#per-package-vendor-licenses).

## Documentation

- [USAGE.md](docs/USAGE.md) — Installation, configuration, examples
- [ARCHITECTURE.md](docs/ARCHITECTURE.md) — Domain model, library API, module structure
- [COMPLIANCE.md](docs/COMPLIANCE.md) — Standards (SALT, OARS, OpenChain)
- [DEVELOPMENT.md](docs/DEVELOPMENT.md) — Testing, domain invariants, pre-commit hooks

## Testing

Over 200,000 checks per `nix flake check` — every license (2649), every usage context, every combination. See [DEVELOPMENT.md](docs/DEVELOPMENT.md) for domain invariants and the full test suite.

```bash
nix flake check   # Run all checks
nix develop       # Dev shell
nix fmt           # Format
```
