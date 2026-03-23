# Usage

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
inputs.nix-license.url = "github:i-am-logger/nix-license";

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
my.users.son.contentPolicy = {
  preset = "child";
  violence-cartoon = "moderate";
};
```

## Usage declaration

All fields are required. You must explicitly answer every question.

### Who you are (`type`)

| Value | Description |
|-------|-------------|
| `personal` | Individual, non-commercial use |
| `commercial` | For-profit business |
| `educational` | School, university, teaching |
| `research` | Academic or scientific research |
| `government` | Government agency |
| `nonprofit` | Registered nonprofit organization |

### What you do (activity flags)

Each flag matches a [SALT](https://github.com/i-am-logger/salt) restriction key:

| Flag | Question | When to set true |
|------|----------|-----------------|
| `commercial-use` | Are you using software for commercial purposes? | Any for-profit activity. Freelancers, startups, enterprises. |
| `distribution` | Are you distributing software to others? | Building ISOs, shipping binaries, publishing containers. |
| `modifications` | Are you modifying the software source code? | Patching, forking, applying overlays. |
| `saas` | Are you providing the software as a hosted or managed service? | Running software that others access over the network as a service. |

## Examples

### Personal user

A hobbyist who modifies packages but doesn't distribute or sell anything.

```nix
usage = {
  type = "personal";
  commercial-use = false;
  distribution = false;
  modifications = true;
  saas = false;
};
```

### Company (internal tools)

A company using open source internally. Modifies code but doesn't distribute.

```nix
usage = {
  type = "commercial";
  commercial-use = true;
  distribution = false;
  modifications = true;
  saas = false;
};
```

### SaaS company

A company that hosts open source software as a service for customers.

```nix
usage = {
  type = "commercial";
  commercial-use = true;
  distribution = true;
  modifications = true;
  saas = true;
};
```

### University

An educational institution distributing course materials and modified tools.

```nix
usage = {
  type = "educational";
  commercial-use = false;
  distribution = true;
  modifications = true;
  saas = false;
};
```

### Freelancer

An individual making money from software. Commercial use, but not distributing or running SaaS.

```nix
usage = {
  type = "commercial";
  commercial-use = true;
  distribution = false;
  modifications = true;
  saas = false;
};
```

### NixOS ISO builder

Someone building and distributing a custom NixOS ISO.

```nix
usage = {
  type = "personal";
  commercial-use = false;
  distribution = true;
  modifications = true;
  saas = false;
};
```

## Commitments

Declare which license obligations you can fulfill. If an obligation triggers and you can't commit to it, the package is blocked.

```nix
commitments = {
  include-copyright = true;      # default: true
  disclose-source = false;       # can't share source → blocks copyleft on distribution
  same-license = false;          # can't open-source → blocks GPL, AGPL
  same-license--file = true;     # can do per-file (MPL)
  same-license--library = true;  # can do library linking (LGPL)
  document-changes = true;       # default: true
  network-use-disclose = false;  # can't share source for network use → blocks AGPL on SaaS
};
```

## Assurances

Require licenses to guarantee specific protections. If a license disclaims something you require, the package is blocked.

```nix
assurances = {
  patent-grant = true;        # block licenses that disclaim patent rights
  liability-coverage = false; # default: false
  warranty = false;           # default: false
};
```

## Content policy

Per-user content policies based on [OARS 1.1](https://github.com/hughsie/oars). This is a **runtime** feature — the resolved policy is written to `/etc/nix-license/content-policy/` as immutable files (symlinks to the Nix store). Apps and launchers query these files to decide what content to show.

```
/etc/nix-license/content-policy/system.json   # system-wide default
/etc/nix-license/content-policy/logger.json   # per-user (via mynixos)
/etc/nix-license/content-policy/son.json      # per-user (via mynixos)
```

### Presets

| Preset | Description |
|--------|-------------|
| `child` | Restrictive — no violence, social, gambling, adult content |
| `teen` | Moderate — allows mild/moderate in most categories |
| `unrestricted` | Everything allowed (default) |

### Per-category overrides

```nix
my.users.son.contentPolicy = {
  preset = "child";
  violence-cartoon = "moderate";  # allow a bit more cartoon violence
};
```

### Severity levels

`none` < `mild` < `moderate` < `intense`

A policy of `violence-cartoon = "moderate"` allows packages rated `none`, `mild`, or `moderate` for that category, but blocks `intense`.

### Build-time content enforcement

Requires packages to have `meta.contentRating` (OARS attrset). nixpkgs does not currently provide this data. See [#15](https://github.com/i-am-logger/nix-license/issues/15) for the overlay approach to sourcing OARS ratings from AppStream.

## Enforcement

| Level | Behavior |
|-------|----------|
| `warn` (default) | Non-compliant packages produce trace warnings but are allowed |
| `enforce` | Non-compliant packages fail at eval time |

```nix
nix-license.enforcement = "enforce";
```

Both modes evaluate every unfree package against your declared usage via `allowUnfreePredicate`. In warn mode, conflicts are logged with `builtins.trace` and the package is allowed. In enforce mode, the build fails.

## Per-package vendor licenses

Some packages require a commercial license from their vendor. You declare the token and tell nix-license to require it:

```nix
nix-license = {
  tokenVerification.requireTokens = [ "vendor-package" "another-tool" ];

  # Vendor provides a signed token proving your license
  licenses."vendor-package" = {
    license = "commercial";
    licenseId = "LIC-2026-XXXXX";           # for your records
    tokenFile = ./secrets/vendor-package.json;   # signed token from vendor
  };

  licenses."another-tool" = {
    license = "commercial";
    token = ''{"package":"another-tool","commercial":true,"licensee":"Acme Corp"}'';
  };
};
```

Packages in `requireTokens` without a matching entry in `licenses` are blocked in enforce mode.

Vendors sign tokens with their own keys (any algorithm — Ed25519, RSA, ECDSA). Vendor public keys are configured via:

```nix
nix-license.vendorKeys = {
  "vendor.example.com" = [ ./keys/vendor-pubkey.pem ];
};
```
