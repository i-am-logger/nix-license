# Standards Compliance

nix-license derives its data from upstream standards at build time. Categories, license definitions, and term enums are fetched as flake inputs and parsed during Nix evaluation — not hand-maintained.

## Content ratings: OARS 1.1

Content policies use the [Open Age Ratings Service 1.1](https://github.com/hughsie/oars/blob/master/specification/oars-1.1.md) specification. OARS is maintained by the GNOME project and adopted by Flathub, GNOME Software, and AppStream.

### How we derive from the spec

The `oars` flake input points to `github:hughsie/oars`. At eval time, we parse the RNC schema (`specification/oars-1.1.rnc`) and extract:
- All content attribute IDs (the `ids` enum)
- All severity values (the `values` enum)

These drive `oarsSpec.categories` and `oarsSpec.severityValues`, which the rest of the system uses. No category list is hand-maintained.

### Official OARS 1.1 attributes (22 categories, derived from RNC)

| Group | Attributes |
|-------|-----------|
| violence | `violence-cartoon`, `violence-fantasy`, `violence-realistic`, `violence-bloodshed`, `violence-sexual`, `violence-desecration`, `violence-slavery` |
| drugs | `drugs-alcohol`, `drugs-narcotics`, `drugs-tobacco` |
| sex | `sex-nudity`, `sex-themes` |
| language | `language-profanity`, `language-humor`, `language-discrimination` |
| social | `social-chat`, `social-info`, `social-audio`, `social-location`, `social-contacts` |
| money | `money-purchasing`, `money-gambling` |

### Severity values (from spec)

| Value | Meaning |
|-------|---------|
| `unknown` | No information available |
| `none` | Not present |
| `mild` | Mild presence |
| `moderate` | Moderate presence |
| `intense` | Intense presence |

### Tests against OARS

- `oarsCategoriesMatchSpec` — verifies our categories exactly equal what the RNC schema defines
- All policy presets are verified to cover every category from the spec
- Severity ordering is exhaustively tested (all 22 × 22 comparisons)

### Related standards

OARS feeds into [IARC](https://www.globalratings.com/) (International Age Rating Coalition), which maps to regional rating boards:

| IARC Generic | PEGI | ESRB | USK |
|-------------|------|------|-----|
| 3 | 3 | E | 0 |
| 7 | 7 | E10+ | 6 |
| 12 | 12 | T | 12 |
| 16 | 16 | M | 16 |
| 18 | 18 | AO | 18 |

nix-license presets (`child`, `teen`, `unrestricted`) roughly correspond to IARC 7, IARC 12, and no restriction.

## License identifiers and metadata: SPDX

License identifiers follow the [SPDX License List](https://spdx.org/licenses/). SPDX is maintained by the Linux Foundation and is the industry standard for license identification.

### How we derive from the spec

The `spdx-license-data` flake input points to `github:spdx/license-list-data`. At eval time, we parse `json/licenses.json` and extract per license:
- `licenseId` — canonical SPDX identifier
- `name` — human-readable name
- `isOsiApproved` — OSI approval status
- `isFsfLibre` — FSF recognition status
- `isDeprecatedLicenseId` — deprecation status

### SPDX fields used

| SPDX field | nix-license field | Usage |
|------------|-------------------|-------|
| `licenseId` | `spdxId` | License key and identifier |
| `name` | `fullName` | Human-readable name |
| `isOsiApproved` | `isOsiApproved` | Exposed directly |
| `isFsfLibre` | `isFsfLibre` | Exposed directly |
| `isOsiApproved \|\| isFsfLibre` | `free` | Determines if `allowClosedSource` applies |

### Tests against SPDX

- All derived licenses have a valid `spdxId` that exists in the SPDX list
- `isOsiApproved` and `isFsfLibre` are passed through unmodified from SPDX

## License terms: choosealicense.com

License permissions, conditions, and limitations are derived from [choosealicense.com](https://github.com/github/choosealicense.com), which GitHub uses for its [Licenses API](https://docs.github.com/en/rest/licenses/licenses).

### How we derive from the spec

The `choosealicense` flake input points to `github:github/choosealicense.com/gh-pages`. At eval time, we parse the YAML frontmatter from each `_licenses/*.txt` file and extract:
- `permissions` — what users can do
- `conditions` — what users must do
- `limitations` — what is not granted

### Official choosealicense.com enums

**Permissions** (derived from upstream):

| Enum | Description |
|------|-------------|
| `commercial-use` | Use for commercial purposes |
| `distribution` | Distribute the software |
| `modifications` | Modify the software |
| `patent-use` | Use patents under the license |
| `private-use` | Use privately |

**Conditions** (derived from upstream):

| Enum | Description |
|------|-------------|
| `include-copyright` | Include copyright notice |
| `include-copyright--source` | Include copyright in source |
| `document-changes` | Document changes made |
| `disclose-source` | Disclose source code |
| `network-use-disclose` | Disclose source for network use |
| `same-license` | Use same license for derivatives |
| `same-license--file` | Same license per file |
| `same-license--library` | Same license for libraries |

**Limitations** (derived from upstream):

| Enum | Description |
|------|-------------|
| `liability` | No liability |
| `warranty` | No warranty |
| `patent-use` | No patent rights |
| `trademark-use` | No trademark rights |

### Mapping to nix-license

nix-license inverts the choosealicense model: instead of listing what you CAN do (permissions), we list what you CANNOT do (restrictions). This is because nix-license evaluates from the user's perspective ("does my usage conflict with this license?").

| nix-license restriction | choosealicense source | Relationship |
|------------------------|----------------------|--------------|
| `restrictions.commercial` | `commercial-use` permission absent | Inverse |
| `restrictions.redistribution` | `distribution` permission absent | Inverse |
| `restrictions.modification` | `modifications` permission absent | Inverse |
| `restrictions.saas` | (nix-license extension) | No choosealicense equivalent |
| `restrictions.military` | (nix-license extension) | No choosealicense equivalent |
| `restrictions.government` | (nix-license extension) | No choosealicense equivalent |

| nix-license obligation | choosealicense condition | Mapping |
|-----------------------|------------------------|---------|
| `obligations.sourceDisclosure` | `disclose-source`, `network-use-disclose` | Direct |
| `obligations.copyleft` | `same-license`, `same-license--file`, `same-license--library` | Direct (grouped) |
| `obligations.licenseInclusion` | `include-copyright`, `include-copyright--source` | Direct (grouped) |
| `obligations.stateChanges` | `document-changes` | Direct |

### Tests against choosealicense.com

- All derived licenses preserve the raw `choosealicense` data (permissions, conditions, limitations)
- `licenses._meta.allPermissions`, `allConditions`, `allLimitations` expose the complete enum sets from upstream
- Restriction/obligation mappings are verified against all usage contexts

### Why the inversion?

choosealicense.com answers: "What does this license let me do?"
nix-license answers: "Does my usage conflict with this license?"

The inversion is necessary because nix-license filters packages based on the user's declared usage context. When `usage.type = "commercial"` and a license has `restrictions.commercial = true`, the package is excluded.

## Manual additions

Licenses not in choosealicense.com are manually defined:

| License | Reason |
|---------|--------|
| `SSPL-1.0` | Server Side Public License — not in choosealicense |
| `Elastic-2.0` | Elastic License — not in choosealicense |
| `Hippocratic` | Hippocratic License — not in SPDX or choosealicense |
| `Unfree` | nixpkgs convention for proprietary software |
| `Unfree-redistributable` | nixpkgs convention (e.g., NVIDIA drivers) |
| `Unfree-redistributable-firmware` | nixpkgs convention for firmware blobs |
| `Academic-only` | Educational-use-only licenses with `allowedUsageTypes` |

## License compliance process: OpenChain ISO/IEC 5230

[OpenChain ISO/IEC 5230:2020](https://openchainproject.org/license-compliance) is an international standard for open source license compliance **programs**. It certifies that an organization has the policies, training, and processes to manage licenses — it does not certify software tools.

nix-license is not an OpenChain program. It is a build-time enforcement tool that an OpenChain-compliant organization can use.

The difference matters: OpenChain requires a human process ("review licenses before shipping"). nix-license replaces that step with automated enforcement — if the license conflicts with the declared usage, the build fails. There is no "forgot to check" because the check is the build.

| OpenChain requirement | nix-license role |
|----------------------|-----------------|
| Written open source policy | Organization declares `usage.type`, `allowClosedSource`, `contentPolicy` in their NixOS config — the policy is code |
| Process to review inbound licenses | `evaluateLicenseUsage` runs at build time for every package, automatically |
| Process to review outbound obligations | `usage.redistribution`, `usage.saas` flags trigger obligation warnings at build time |
| Ability to produce SBOM | Future work: export license data from the system closure |
| Training, designated person, issue tracking | Outside nix-license scope — these are organizational requirements |

Organizations using nix-license get automated enforcement of the technical compliance decisions. The organizational requirements (who decides the policy, who is responsible, how are issues tracked) remain the organization's responsibility.

## Software bill of materials: SPDX / CycloneDX

nix-license license definitions carry SPDX identifiers and can be exported as part of an SBOM. The `spdxId` field maps directly to SPDX license expressions, and the `restrictions`/`obligations` metadata can inform CycloneDX license property fields.

This integration is future work — see the [Usage-Context RFC](rfc-usage-context-license-model.md) future possibilities section.

## Cryptographic tokens

The token format is nix-license specific (no existing standard covers offline license verification for package managers). The design draws from:

| Prior art | What we took from it |
|-----------|---------------------|
| [Biscuit](https://biscuitsec.org/) | Token restriction model — tokens can only be made more restrictive |
| [Macaroons](https://research.google/pubs/macaroons-cookies-with-contextual-caveats-for-decentralized-authorization-in-the-cloud/) | Contextual caveats, delegation chains |
| JetBrains licensing | Signed offline license files as prior art |
| Ed25519 | Signature algorithm (small keys, fast verification, no patents) |

The token authorization fields reuse the same enums as the license restriction/obligation model for consistency.

## Updating standards

```bash
nix flake update oars              # Update OARS content rating spec
nix flake update spdx-license-data # Update SPDX license list
nix flake update choosealicense    # Update choosealicense.com terms
nix flake check                    # Verify everything still passes
```
