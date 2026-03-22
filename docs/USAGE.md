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

## Content policy

Content policies control what software is available per user based on [OARS 1.1](https://github.com/hughsie/oars) content ratings.

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

## Enforcement

| Level | Behavior |
|-------|----------|
| `warn` (default) | Log warnings for restriction conflicts |
| `enforce` | Block builds for restriction conflicts |

```nix
nix-license.enforcement = "enforce";
```
