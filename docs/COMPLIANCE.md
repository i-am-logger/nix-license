# Standards Compliance

## License data: SALT

All license data comes from [SALT](https://github.com/i-am-logger/salt) (Software And License Taxonomy). nix-license uses SALT terms directly — no mapping.

SALT provides 2649 licenses classified with:
- **Grants**: what the license permits
- **Obligations**: what you must do
- **Restrictions**: what the license prohibits (`commercial-use`, `distribution`, `modifications`, `saas`)
- **Disclaimers**: what the license doesn't guarantee

nix-license's usage flags match SALT restriction keys exactly. If a license restricts `commercial-use` and the user declares `commercial-use = true`, the build fails.

## Content ratings: OARS 1.1

Content policies use the [Open Age Ratings Service 1.1](https://github.com/hughsie/oars) specification (22 categories, derived from upstream RNC schema at build time).

## Restriction vocabulary: OSADL

SALT's restriction vocabulary is derived from [OSADL OSLOC](https://github.com/osadl/OSLOC) (Open Source License Obligation Checklists), the most rigorous atomic-level taxonomy for license terms.

| SALT restriction | OSADL source |
|---|---|
| `commercial-use` | Implied by license category |
| `distribution` | USE CASE Source code/Binary delivery |
| `modifications` | Implied by license terms |
| `saas` | USE CASE Network service |

## Build-time enforcement

When `nix-license.enable = true`:

1. `nixpkgs.config.allowUnfree` is set to `true` — bypasses nixpkgs' binary free/unfree check
2. nix-license handles all license compliance using SALT restrictions
3. Usage consistency assertions catch invalid configurations (e.g., `type = "personal"` with `commercial-use = true`)

## License compliance process: OpenChain ISO/IEC 5230

[OpenChain ISO/IEC 5230](https://openchainproject.org/license-compliance) certifies organizational compliance programs. nix-license provides build-time enforcement that supports such programs:

| OpenChain requirement | nix-license role |
|---|---|
| Written open source policy | Usage declaration in NixOS config is the policy |
| Process to review licenses | `evaluateLicenseUsage` runs at build time |
| Ability to produce SBOM | Future work |

## Token verification

License tokens use GPG signatures (Ed25519 via YubiKey). The token system draws from [Biscuit](https://biscuitsec.org/) (restriction model) and [Macaroons](https://research.google/pubs/macaroons-cookies-with-contextual-caveats-for-decentralized-authorization-in-the-cloud/) (delegation chains).
