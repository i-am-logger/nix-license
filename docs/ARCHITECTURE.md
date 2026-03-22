# Architecture

## Structure

```
nix-license/
├── lib/
│   ├── types.nix             # OARS categories + severity values (from upstream RNC schema)
│   ├── content-rating.nix    # Content policy resolution and evaluation
│   ├── license-check.nix     # License restriction + allowed-use evaluation
│   ├── licenses.nix          # License definitions from SALT
│   ├── nixpkgs-map.nix       # Maps nixpkgs licenses to SALT (spdxId → manual → key)
│   └── token.nix             # Token construction, restriction, validation
├── modules/
│   ├── default.nix           # Standalone NixOS module (nix-license.*)
│   └── mynixos.nix           # mynixos integration (my.license.* + my.users.<name>.*)
├── tests/
│   ├── lib-types.nix         # OARS categories, presets
│   ├── lib-content-rating.nix # Severity, policy resolution, content evaluation
│   ├── lib-licenses.nix      # License restriction + allowed-use checks
│   ├── lib-token.nix         # Token authorization, restriction, expiry
│   ├── lib-properties.nix    # Domain model guarantees
│   ├── nixpkgs-map.nix       # 289/289 nixpkgs→SALT mapping + end-to-end evaluation
│   └── module-standalone.nix # NixOS module scenarios + assertion tests
└── docs/
```

## Data sources

| Flake input | Source | What we use |
|-------------|--------|-------------|
| `salt` | [i-am-logger/salt](https://github.com/i-am-logger/salt) | 2649 license classifications |
| `oars` | [hughsie/oars](https://github.com/hughsie/oars) | Content rating categories from RNC schema |

## License evaluation

Two independent checks per license:

1. **Restrictions** (blocklist): if the license restricts an activity and the user does that activity → conflict (unless exempted)
2. **Allowed-use** (allowlist): if the license specifies who can use it and the user's type isn't in the list → conflict
3. **Commitments**: if an obligation triggers and the user can't commit to fulfilling it → conflict
4. **Assurances**: if the license disclaims something the user requires → conflict

All must pass.

## nixpkgs mapping

`lib/nixpkgs-map.nix` maps every nixpkgs license to its SALT equivalent. Lookup order:

1. `spdxId` → `salt.spdx.${spdxId}` (234 licenses)
2. Manual map for known mismatches (55 entries, e.g. `asl20` → `apache-2.0`, `unfree` → `proprietary-license`)
3. `shortName` → `salt.licenses.${shortName}` (direct key match)
4. `null` → module throws (unknown license must fail)

All 289 nixpkgs licenses are verified to map successfully (tested in `nixpkgs-map.nix`).

## Usage declaration

```nix
usage = {
  type = "commercial";     # who you are (checked against allowed-use)
  commercial-use = true;   # what you do (checked against restrictions)
  distribution = false;
  modifications = true;
  saas = false;
};
```

All fields required, no defaults.

## Library API

### License evaluation (`lib.licenseCheck`)

| Function | Description |
|----------|-------------|
| `evaluateLicenseUsage` | Check usage against license restrictions + allowed-use |

### Content rating (`lib.contentRating`)

| Function | Description |
|----------|-------------|
| `severityAllowed` | Is this severity level within the policy maximum? |
| `resolveContentPolicy` | Resolve a preset or attrset into a full content policy |
| `evaluateContentRating` | Evaluate a package's content rating against a policy |

### License tokens (`lib.token`)

| Function | Description |
|----------|-------------|
| `mkLicenseToken` | Create a license token |
| `evaluateTokenAuthorizations` | Check token authorizations against usage |
| `isValidTokenRestriction` | Can this token be restricted further? |
| `restrictToken` | Apply a restriction (returns null if invalid) |
| `validateToken` | Full token validation |

## Domain model guarantees

| Guarantee | Verified by |
|-----------|-------------|
| Empty usage = no conflicts | lib-properties |
| Adding usage flags never removes conflicts | lib-properties |
| No restrictions = universally allowed | lib-properties |
| Severity levels form a total order | lib-properties |
| Content policy presets are ordered (child < teen < unrestricted) | lib-properties |
| Relaxing a policy never removes access | lib-properties |
| All 289 nixpkgs licenses map to SALT | nixpkgs-map |
| All 289 × 4 usage contexts evaluate without error | nixpkgs-map |
| Usage assertions catch invalid combinations | module-standalone |
| Enforce mode sets allowUnfree=false with predicate | module-standalone |
