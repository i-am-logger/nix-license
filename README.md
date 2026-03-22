[![NixOS](https://img.shields.io/badge/NixOS-5277C3?logo=nixos&logoColor=white)](https://nixos.org)
[![Release](https://img.shields.io/github/v/release/i-am-logger/nix-license)](https://github.com/i-am-logger/nix-license/releases)
[![CI and Release](https://github.com/i-am-logger/nix-license/actions/workflows/ci-and-release.yml/badge.svg)](https://github.com/i-am-logger/nix-license/actions/workflows/ci-and-release.yml)
[![OARS 1.1](https://img.shields.io/badge/OARS-1.1-blue)](https://github.com/hughsie/oars)
[![SPDX](https://img.shields.io/badge/SPDX-License%20List-blue)](https://spdx.org/licenses/)

# nix-license

License and content compliance enforced at build time.

You declare your usage context, content policies, and license entitlements in your NixOS configuration. nix-license evaluates every package against those declarations during the build. If a package conflicts with your policy, the build fails. There is no separate audit step, no report to review, no check to remember — compliance is the build.

## The problem

`allowUnfree = true` is a single boolean that conflates three separate concerns: whether you accept closed-source software, how you're using the software, and whether certain content is appropriate for certain users.

A company that sets `allowUnfree = true` to get NVIDIA drivers has silently allowed CC-BY-NC software that prohibits commercial use. A parent who wants to restrict what apps their child can run has no mechanism for it. A school that needs educational-use-only software has no way to declare that.

Existing compliance tools produce reports. Reports get ignored. nix-license makes non-compliant configurations fail to build.

## Three controls

nix-license replaces `allowUnfree` with three independent declarations:

1. **Source availability** -- do you accept closed-source packages?
2. **Usage context** -- personal, commercial, educational, or government use?
3. **Content policy** -- what content categories is each user entitled to?

## How it works

### Source availability

```nix
nix-license.allowClosedSource = true;
```

Replaces `allowUnfree` for the question "do you accept closed-source packages?"

### Usage context

```nix
nix-license.usage = {
  type = "commercial";
  redistribution = false;
  saas = false;
  military = false;
};
```

Packages carry license restrictions. When your declared usage conflicts with a restriction, the package is unavailable:

```
error: Package 'some-tool' (CC-BY-NC-4.0) restricts commercial use.
       Your declared usage: commercial
```

### Content policy

```nix
# System-wide default
nix-license.contentPolicy.preset = "child";

# Per-user (via mynixos)
my.users.son.contentPolicy = {
  preset = "child";
  violence-cartoon = "moderate";
};

my.users.parent.contentPolicy = "unrestricted";
```

Packages carry [OARS](https://hughsie.github.io/oars/) content ratings. Users carry content entitlements set by the admin. If a package exceeds the user's policy, it's excluded from their environment:

```
error: Package 'discord' requires content license 'social-chat = intense'
       but user 'son' is licensed for maximum 'none'.
```

No PII stored. No birth dates. The admin decides the policy, not the app.

### Content policy presets

| Preset | Description |
|--------|-------------|
| `child` | No violence, social, gambling, adult content |
| `teen` | Allows mild/moderate in most categories |
| `unrestricted` | Everything allowed (default) |

Content categories follow [OARS](https://hughsie.github.io/oars/) (already used by Flathub, GNOME Software, AppStream): violence, drugs, sex, language, social, money -- each with severity levels `none` < `mild` < `moderate` < `intense`.

### Commercial license tokens

For purchased commercial software, declare the license:

```nix
nix-license.licenses."vendor-sdk" = {
  license = "commercial";
  licenseId = "LIC-2024-XXXXX";
  expiresAt = "2025-06-15";
  tokenFile = ./secrets/vendor-sdk.token;
};
```

Tokens are cryptographically signed by the vendor. Verification happens at build time with no network access -- tokens are self-contained proof of license.

Organizations can restrict tokens per-user. A restricted token can only remove permissions, never add them:

```nix
my.users.intern.licenseTokens."vendor-sdk".tokenFile = ./secrets/intern.token;
```

### Vendor key management

```nix
nix-license.vendorKeys."vendor.example.com" = [ "ed25519:MCowBQYDK2VwAyEA..." ];

nix-license.tokenVerification = {
  enable = true;
  requireTokens = [ "vendor-sdk" ];
  warnExpiringSoon = 30;
};
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
            allowClosedSource = true;
            usage.type = "personal";
          };
        }
      ];
    };
  };
}
```

### With mynixos

```nix
inputs.nix-license.url = "github:i-am-logger/nix-license";

# In module imports
imports = [
  nix-license.nixosModules.default    # nix-license.* options
  nix-license.nixosModules.mynixos    # my.license.* + my.users.<name>.contentPolicy
];
```

```nix
my.license = {
  enable = true;
  allowClosedSource = true;
  usage.type = "personal";
};

my.users.logger.contentPolicy = "unrestricted";
my.users.son.contentPolicy = {
  preset = "child";
  violence-cartoon = "moderate";
};
```

## Standards

nix-license derives its data from upstream standards at build time. Categories, license definitions, and term enums are not hand-maintained — they are parsed from upstream repos included as flake inputs. `nix flake update <input>` picks up upstream changes.

| Standard | Flake input | Upstream repo | What we derive |
|----------|-------------|---------------|----------------|
| OARS 1.1 | `oars` | [hughsie/oars](https://github.com/hughsie/oars) | 22 content rating categories + severity values from RNC schema |
| SPDX License List | `spdx-license-data` | [spdx/license-list-data](https://github.com/spdx/license-list-data) | 600+ license identifiers, names, OSI/FSF approval from JSON |
| choosealicense.com | `choosealicense` | [github/choosealicense.com](https://github.com/github/choosealicense.com) | 47 licenses with permissions, conditions, limitations from YAML |
| OpenChain ISO/IEC 5230 | (reference) | [openchainproject.org](https://openchainproject.org/license-compliance) | Build-time enforcement layer for compliance programs |
| Biscuit / Macaroons | (design influence) | [biscuitsec.org](https://biscuitsec.org/) | Token restriction model |

See [COMPLIANCE.md](docs/COMPLIANCE.md) for detailed mappings and deviations.

## Documentation

| Document | Contents |
|----------|----------|
| [COMPLIANCE.md](docs/COMPLIANCE.md) | Standards mapping (OARS, SPDX, GitHub API, OpenChain) |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Library API, module structure, domain model guarantees, test coverage |
| [Usage-Context RFC](docs/rfc-usage-context-license-model.md) | Replace `allowUnfree` with source-availability and usage-context axes |
| [Cryptographic Tokens RFC](docs/rfc-cryptographic-license-tokens.md) | Offline-verifiable license tokens for Nix builds |
| [Content Policy RFC](docs/rfc-content-policy-model.md) | Content category entitlements as a third licensing axis |

## Development

```bash
nix develop       # Dev shell with pre-commit hooks
nix flake check   # Run all checks (formatting, linting, 7 test suites)
nix fmt           # Format all files
```
