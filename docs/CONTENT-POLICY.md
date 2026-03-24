# Content Policy

Content policy controls what software content each user on a system is entitled to access — violence levels, gambling, adult content, social features, and more. The administrator sets the policy. Apps query it at runtime. The system enforces it consistently.

## A proven model

Content rating has been the industry standard for decades:

| Industry | System | How it works |
|----------|--------|-------------|
| Movies | MPAA (G, PG, PG-13, R, NC-17) | Rate the content, not the viewer |
| Television | TV Parental Guidelines (TV-Y, TV-PG, TV-MA) | Per-show rating, V-chip enforces |
| Games | ESRB (E, T, M, AO) / PEGI (3, 7, 12, 16, 18) | Per-game rating, platform enforces |
| Music | Parental Advisory | Label the content, parent decides |
| Apps | OARS / IARC | App stores rate and filter |

Every industry rates the **content**, then lets a **gatekeeper** (parent, platform, broadcaster) decide what to allow. Nobody asks the viewer for their birth certificate.

nix-license applies this same model to software — rate the content (OARS 1.1), set the policy (administrator), enforce at the system level.

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

The policy file contains only severity levels per content category — what the user is entitled to, not who the user is. The resolved file stores no preset name, no age, no identity — just severity levels like `"violence-cartoon": "mild"`.

**Limitation:** content policy protects the local system. If the user accesses a SaaS application, the service may still collect behavioral data regardless of local policy. No legislation currently requires services to stop storing user history — age verification laws address the gate but not the surveillance behind it.

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

Per-user content entitlements based on [OARS 1.1](https://github.com/hughsie/oars) (Open Age Ratings Service).

### Severity levels

Each category is rated on a four-level scale:

| Level | Meaning |
|-------|---------|
| `none` | No content of this type |
| `mild` | Minor or infrequent |
| `moderate` | Present but not dominant |
| `intense` | Frequent or graphic |

A policy of `violence-cartoon = "moderate"` allows packages rated `none`, `mild`, or `moderate` for that category, but blocks `intense`.

### Categories

22 content categories derived from the upstream RNC schema:

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


## Presets

| Preset | Description |
|--------|-------------|
| `restricted` | Restrictive — blocks violence, social, gambling, adult content |
| `moderate` | Moderate — allows mild/moderate in most categories |
| `unrestricted` | Everything allowed (default) |

## Configuration

### System-wide default

```nix
nix-license.contentPolicy = {
  preset = "moderate";
};
```

### Per-user (via mynixos)

```nix
my.users.logger.contentPolicy = "unrestricted";

my.users.guest.contentPolicy = {
  preset = "restricted";
  violence-cartoon = "moderate";  # allow some cartoon violence
};
```

### Per-category overrides

Any category can be overridden regardless of preset:

```nix
my.users.teen.contentPolicy = {
  preset = "moderate";
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
└── guest.json        # guest:root 0400 — user-specific
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
| restricted < teen < unrestricted | `content-rating/policy` |
| Relaxing a policy never removes access | `content-rating/policy` |
| Resolving a policy is stable (idempotent) | `content-rating/policy` |
