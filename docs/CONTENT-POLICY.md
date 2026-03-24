# Content Policy

## The problem with age verification

California (AB 2273), Colorado, New York, and other states are pushing age verification laws that require platforms to verify users' ages before allowing access to content.

| | Age verification | Content policy |
|---|---|---|
| **Privacy** | Requires PII (birth date, ID scan, face scan) | No PII — administrator sets policy |
| **Who decides** | Each app interprets age differently | Administrator decides once, system enforces |
| **Enforcement** | App-by-app, inconsistent | System-wide, one policy per user |
| **Data storage** | Age data stored or verified per app | No user data stored |
| **Granularity** | Binary (old enough or not) | 22 categories × 4 severity levels |
| **Control** | User/platform | Parent/admin/organization |

Age verification asks: **"How old is the user?"** and lets every app interpret that differently.

Content policy asks: **"What is this user entitled to?"** and enforces it consistently at the system level.

## No PII by design

nix-license content policy stores **zero personally identifiable information**:

- No birth dates, no age data
- No ID documents, no biometric data
- No user accounts, no passwords
- No network requests to verify identity

The policy file contains only severity levels per content category — what the user is entitled to, not who the user is.

**Are preset names like "child" and "teen" PII?** No. These are policy PRESET names, not user attributes. The system doesn't store that a user IS a child — it stores that a user's content entitlement MATCHES the "child" preset. The resolved policy file contains only severity levels (`"violence-cartoon": "mild"`), not the preset name. Even if leaked, it reveals nothing about the user's identity or age — only their content entitlements.

The username in the filename (e.g., `son.json`) is system configuration set by the administrator, not collected user data. It exists regardless of nix-license — NixOS always has usernames.

## How it works

```mermaid
graph LR
    ADMIN[Administrator] -->|sets policy| CONFIG[NixOS Config]
    CONFIG -->|builds| FILES["/etc/nix-license/content-policy/"]
    FILES -->|reads| APP[Application]
    APP -->|decides| SHOW[Show content]
    APP -->|decides| HIDE[Hide content]
```

1. Administrator declares content policies in NixOS config
2. nix-license writes resolved policies to `/etc/nix-license/content-policy/` as immutable Nix store symlinks
3. Apps read the policy file and decide what to show

nix-license provides the policy. Apps enforce it.

## OARS 1.1

Per-user content entitlements based on [OARS 1.1](https://github.com/hughsie/oars) (Open Age Ratings Service). 22 content categories derived from the upstream RNC schema:

| Category | Examples |
|----------|---------|
| `violence-cartoon` | Cartoon violence |
| `violence-fantasy` | Fantasy violence |
| `violence-realistic` | Realistic violence |
| `violence-bloodshed` | Blood and gore |
| `violence-sexual` | Sexual violence |
| `violence-desecration` | Desecration of corpses |
| `violence-slavery` | Depictions of slavery |
| `drugs-alcohol` | Alcohol use |
| `drugs-narcotics` | Drug use |
| `drugs-tobacco` | Tobacco use |
| `sex-nudity` | Nudity |
| `sex-themes` | Sexual themes |
| `language-profanity` | Profanity |
| `language-humor` | Crude humor |
| `language-discrimination` | Discriminatory language |
| `social-chat` | Online chat |
| `social-info` | Sharing personal info |
| `social-audio` | Voice chat |
| `social-location` | Location sharing |
| `social-contacts` | Contact sharing |
| `money-purchasing` | In-app purchases |
| `money-gambling` | Gambling |

Each category has a severity level: `none` < `mild` < `moderate` < `intense`

## Presets

| Preset | Description |
|--------|-------------|
| `child` | Restrictive — blocks violence, social, gambling, adult content |
| `teen` | Moderate — allows mild/moderate in most categories |
| `unrestricted` | Everything allowed (default) |

## Configuration

### System-wide default

```nix
nix-license.contentPolicy = {
  preset = "teen";
};
```

### Per-user (via mynixos)

```nix
my.users.logger.contentPolicy = "unrestricted";

my.users.son.contentPolicy = {
  preset = "child";
  violence-cartoon = "moderate";  # allow some cartoon violence
};
```

### Per-category overrides

Any category can be overridden regardless of preset:

```nix
my.users.teen.contentPolicy = {
  preset = "teen";
  money-gambling = "none";      # stricter: no gambling
  language-humor = "intense";   # looser: allow crude humor
};
```

## Policy files

Resolved policies are written as immutable JSON files:

```
/etc/nix-license/content-policy/
├── system.json     # root:root 0644 — system default, apps fallback
├── logger.json     # logger:root 0400 — user-specific
└── son.json        # son:root 0400 — user-specific
```

- **System**: readable by all (apps need it as fallback)
- **Per-user**: readable only by that user and root
- **Immutable**: symlinks to Nix store — cannot be modified

### File format

```json
{
  "violence-cartoon": "moderate",
  "violence-fantasy": "none",
  "violence-realistic": "none",
  "drugs-alcohol": "none",
  "sex-nudity": "none",
  "language-profanity": "mild",
  "social-chat": "moderate",
  "money-gambling": "none",
  "money-purchasing": "mild",
  "allowUnrated": false
}
```

No preset name, no age, no identity — just severity levels.

## Runtime enforcement

Apps read the policy file and decide what to show:

```python
# pseudocode
import json, os

user = os.getenv("USER")
path = f"/etc/nix-license/content-policy/{user}.json"
if not os.path.exists(path):
    path = "/etc/nix-license/content-policy/system.json"

policy = json.load(open(path))

if severity_level(app_rating["violence-realistic"]) > severity_level(policy["violence-realistic"]):
    hide_or_block()
```

nix-license does not enforce content policy at runtime — it provides the policy. Enforcement is the app's responsibility.

## Build-time enforcement

Build-time content checking requires packages to have `meta.contentRating` (an OARS attrset). nixpkgs does not currently provide this data.

See [#15](https://github.com/i-am-logger/nix-license/issues/15) for the overlay approach to sourcing OARS ratings from AppStream metadata.

## Domain invariants

The content policy system is verified by exhaustive testing:

| Property | Verified by |
|----------|-------------|
| Severity levels form a total order | `content-rating/severity` |
| child < teen < unrestricted | `content-rating/policy` |
| Relaxing a policy never removes access | `content-rating/policy` |
| Resolving a policy is stable (idempotent) | `content-rating/policy` |
