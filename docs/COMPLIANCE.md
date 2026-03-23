# Standards Compliance

## License data: SALT

All license data comes from [SALT](https://github.com/i-am-logger/salt) (Software And License Taxonomy). nix-license uses SALT terms directly — no mapping.

SALT provides 2649 licenses classified with:
- **Grants**: what the license permits
- **Obligations**: what you must do
- **Restrictions**: what the license prohibits (`commercial-use`, `distribution`, `modifications`, `saas`, `endorsement`, `competing-use`)
- **Disclaimers**: what the license doesn't guarantee

nix-license's usage flags match SALT restriction keys exactly. If a license restricts `commercial-use` and the user declares `commercial-use = true`, the build fails.

## Content ratings: OARS 1.1

Content policies use the [Open Age Ratings Service 1.1](https://github.com/hughsie/oars) specification (22 categories, derived from upstream RNC schema at build time).

## Restriction vocabulary

SALT defines its own vocabulary for restrictions (`commercial-use`, `distribution`, `modifications`, `saas`), obligations, and disclaimers. These terms were validated against [OSADL OSLOC](https://github.com/osadl/OSLOC) (Open Source License Obligation Checklists) to ensure alignment with established legal concepts, but SALT is an independent taxonomy — not a mapping of OSADL.

## Build-time enforcement

When `nix-license.enable = true`:

1. Every nixpkgs license is mapped to its SALT equivalent (289/289 verified)
2. Each package's license is evaluated against your declared usage
3. Usage consistency assertions catch invalid configurations (e.g., `type = "personal"` with `commercial-use = true`)

Two enforcement modes:

| Mode | Behavior |
|------|----------|
| `warn` (default) | Non-compliant packages produce `builtins.trace` warnings but are allowed |
| `enforce` | Non-compliant packages fail at eval time |

nix-license applies an overlay that marks all licenses as `free = false`, ensuring `allowUnfreePredicate` fires for every package — including copyleft licenses like GPL and AGPL. This means commitment checks (e.g., `same-license.fulfilled = false`) correctly block copyleft packages.

## License compliance process: OpenChain ISO/IEC 5230

[OpenChain ISO/IEC 5230](https://openchainproject.org/license-compliance) certifies organizational compliance programs. nix-license provides build-time enforcement that supports such programs:

| OpenChain requirement | nix-license role |
|---|---|
| Written open source policy | Usage declaration in NixOS config is the policy |
| Process to review licenses | Every package's license is evaluated against declared usage at build time |
| License identification | All 289 nixpkgs licenses mapped to [SALT](https://github.com/i-am-logger/salt) classifications |
| Compliance artifacts | Triggered obligations are tracked per-package |
| Ability to produce SBOM | Future work ([#7](https://github.com/i-am-logger/nix-license/issues/7)) |

See [issue #6](https://github.com/i-am-logger/nix-license/issues/6) for self-certification questionnaire mapping.

## Token verification

Two token verification paths:

| Path | Algorithm | Verifier | Use case |
|------|-----------|----------|----------|
| nix-license self-licensing | GPG/YubiKey (Ed25519) | `gpg --verify` | Commercial use of nix-license itself |
| Vendor package tokens | Any (vendor's choice) | `openssl pkeyutl -verify` | Per-package commercial licenses |

Author public keys are embedded in `keys/`. Vendor public keys are provided via `nix-license.vendorKeys`.
