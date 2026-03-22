# Architecture

## Structure

```
nix-license/
├── lib/
│   ├── types.nix             # OARS categories + severity values (derived from upstream RNC schema)
│   ├── content-rating.nix    # Content policy resolution and evaluation
│   ├── license-check.nix     # License usage and source availability evaluation
│   ├── licenses.nix          # License definitions (derived from SPDX + choosealicense.com)
│   └── token.nix             # Token construction, authorization, restriction, validation
├── modules/
│   ├── default.nix           # Standalone NixOS module (nix-license.*)
│   └── mynixos.nix           # mynixos integration (my.license.* + my.users.<name>.*)
├── tests/
│   ├── lib-types.nix         # OARS categories, presets, coverage
│   ├── lib-content-rating.nix # Severity, policy resolution, content evaluation
│   ├── lib-licenses.nix      # All licenses × all usage contexts
│   ├── lib-token.nix         # Token auth, restriction, expiry, content policy
│   ├── lib-properties.nix    # Domain model guarantees
│   └── module-standalone.nix # NixOS module defaults, configs, scenarios
└── docs/                     # RFCs and compliance documentation
```

## Upstream data sources

All domain data is derived from upstream standards at eval time:

| Flake input | Source | What we parse |
|-------------|--------|---------------|
| `oars` | `github:hughsie/oars` | RNC schema → content rating category IDs + severity values |
| `spdx-license-data` | `github:spdx/license-list-data` | JSON → license identifiers, names, OSI/FSF status |
| `choosealicense` | `github:github/choosealicense.com` | YAML frontmatter → permissions, conditions, limitations per license |

No categories, license IDs, or term enums are hand-maintained. `nix flake update oars` / `spdx-license-data` / `choosealicense` picks up upstream changes.

## Modules

The **standalone module** (`nixosModules.default`) provides system-wide options under `nix-license.*`. Any NixOS system can use it directly.

The **mynixos module** (`nixosModules.mynixos`) adds per-user content policies under `my.users.<name>.contentPolicy` and per-user license tokens under `my.users.<name>.licenseTokens`. It wires `my.license.*` into the standalone module.

## Library API

### Content rating (`lib.contentRating`)

| Function | Description |
|----------|-------------|
| `severityAllowed` | Is this severity level allowed by the policy maximum? |
| `severityLevel` | Maps severity names to their rank (none=0, mild=1, moderate=2, intense=3) |
| `resolveContentPolicy` | Resolve a preset string or attrset into a full content policy |
| `evaluateContentRating` | Evaluate a package's content rating against a policy |
| `allowsUnratedContent` | Does this policy allow unrated packages? |

### License evaluation (`lib.licenseCheck`)

| Function | Description |
|----------|-------------|
| `evaluateLicenseUsage` | Evaluate a license against a usage context -- returns conflicts and obligations |
| `evaluateSourceAvailability` | Is closed-source permitted? |
| `evaluateCompliance` | Full compliance check combining source + usage |

### License tokens (`lib.token`)

| Function | Description |
|----------|-------------|
| `mkLicenseToken` | Create a license token |
| `evaluateTokenAuthorizations` | Evaluate whether a token's authorizations satisfy a usage context |
| `evaluateTokenContentPolicy` | Evaluate token content authorizations against a content policy |
| `isValidTokenRestriction` | Can this token be restricted to these new values? |
| `restrictToken` | Apply a restriction to a token (returns null if it would escalate) |
| `isTokenExpired` | Is a token expired? |
| `validateToken` | Full token validation (authorizations + expiry + package + content) |

### License definitions (`lib.licenses`)

Licenses are derived from SPDX + choosealicense.com, plus manual additions for licenses not covered by those sources (SSPL, Elastic 2.0, Hippocratic, nixpkgs unfree conventions, academic-only).

Each license includes: `spdxId`, `fullName`, `free`, `isOsiApproved`, `isFsfLibre`, `restrictions`, `obligations`, and raw `choosealicense` data where available.

`licenses._meta` provides source metadata: SPDX version, license counts, and the official choosealicense.com enum values for permissions, conditions, and limitations.

## Domain model guarantees

The test suite exhaustively verifies properties across all combinations:

| Guarantee | What it means |
|-----------|---------------|
| Severity levels have a clear scale | none < mild < moderate < intense, no ambiguity |
| OARS categories match upstream spec | Categories are derived from the OARS 1.1 RNC schema, not hand-maintained |
| Presets are strictly ordered | child is always more restrictive than teen, teen than unrestricted |
| Relaxing a policy never removes access | If child allows an app, teen and unrestricted also allow it |
| Resolving a policy twice is the same as once | No surprises from double-processing |
| More restrictions never grant access | Adding a restriction to a license only blocks more contexts |
| Adding capabilities only adds conflicts | Declaring redistribution/SaaS/military only triggers more conflicts |
| Compliance requires both source and usage approval | Passing one check doesn't excuse failing the other |
| No restrictions means universally allowed | Permissive licenses (MIT, BSD, etc.) work for every usage context |
| Commercial use is at least as restricted as personal | No license blocks personal but allows commercial |
| Token restriction can only remove permissions | A restricted token never grants more than the original |
| Chained token restrictions are valid | Org → team → user restriction chains maintain integrity |
| Restricted tokens never grant more than the original | If a restricted token satisfies a usage, the original does too |
| Redistribution only adds obligations | Enabling redistribution never removes existing obligations |

## Test suites

| Suite | Coverage |
|-------|----------|
| `lib-types` | OARS categories match upstream, presets, coverage invariants |
| `lib-content-rating` | Severity comparisons, policy resolution, content evaluation, domain guarantees |
| `lib-token` | Token authorization, restriction rules, expiry, content policy, seats/machines |
| `lib-licenses` | All derived licenses × usage contexts, source availability, compliance, obligations |
| `lib-properties` | Cross-product domain model guarantees across all combinations |
| `module-standalone` | NixOS module defaults, custom configs, real-world scenarios |
| `pre-commit` | statix, deadnix, treefmt formatting |
