# RFC: Content Policy Model

## Summary

This RFC extends the usage-context license model with a **content policy** system that lets administrators control which software categories users can access — without storing any personally identifiable information like birth dates.

Instead of asking "how old is the user?" and letting each app decide what that means, this model asks "what content categories is this user entitled to?" and enforces it at the system level. The administrator (parent, IT admin, school) makes the policy decision once, and the system enforces it consistently.

This is the third axis of the nix-license model:

1. **Source availability** — `allowClosedSource` (RFC: Usage-Context-Based License Model)
2. **Usage context** — `usage.type`, `usage.commercial`, etc. (RFC: Usage-Context-Based License Model)
3. **Content policy** — what content categories are permitted (this RFC)

## Background

### The age verification problem

New laws in California (AB-1043), Colorado (SB26-051), and Brazil (Lei 15.211/2025) require applications to verify user age before granting access to certain content. The current approach being adopted by systemd and Linux desktop projects is to store a birth date in the user record and let applications query it.

This approach has fundamental problems:

- **Stores PII unnecessarily.** A birth date is personally identifiable information. Storing it creates a data protection liability under GDPR, CCPA, and similar regulations — to solve a problem about data protection.
- **Delegates the decision to apps.** Each app interprets the birth date independently. One app might block a 15-year-old, another might allow them. The parent/admin has no control over these decisions.
- **Binary and imprecise.** Age creates a single threshold. But content concerns are multidimensional — a parent might allow moderate video game violence but not gambling mechanics, regardless of age ratings.
- **No enforcement mechanism.** The birth date is advisory. Apps can ignore it. Users can run apps from the CLI, bypassing any portal check.

### The entitlement alternative

Instead of "you are X years old, figure it out," we propose "you are entitled to these content categories." This is:

- **An established pattern.** App stores (Google Play, Apple App Store), game platforms (Steam), and content rating boards (ESRB, PEGI, IARC) already classify content by category. OARS (Open Age Ratings Service) provides a standard schema used by Flathub, GNOME Software, and AppStream.
- **Already in Nix's DNA.** The `allowUnfree` mechanism is exactly this pattern — packages carry metadata (`meta.license`), users declare policy (`allowUnfree`), and Nix enforces at build time. We're extending this to content categories.
- **PII-free.** A content policy contains no personal information. "This user can access games but not gambling apps" reveals nothing about who they are.

### Prior art: OARS

The [Open Age Ratings Service](https://hughsie.github.io/oars/) defines a standardized content rating schema already used across the Linux desktop:

| OARS Category | Description |
|---------------|-------------|
| `violence-cartoon` | Cartoon violence |
| `violence-fantasy` | Fantasy violence |
| `violence-realistic` | Realistic violence |
| `violence-bloodshed` | Bloodshed |
| `violence-sexual` | Sexual violence |
| `violence-desecration` | Desecration of human remains |
| `violence-slavery` | Depiction of slavery |
| `drugs-alcohol` | Alcohol use |
| `drugs-narcotics` | Narcotics use |
| `drugs-tobacco` | Tobacco use |
| `sex-nudity` | Nudity |
| `sex-themes` | Sexual themes |
| `sex-content` | Sexual content |
| `sex-appearance` | Provocative appearance |
| `language-profanity` | Profanity |
| `language-humor` | Crude humor |
| `language-discrimination` | Discriminatory language |
| `social-chat` | Online chat |
| `social-info` | User info sharing |
| `social-audio` | Voice chat |
| `social-location` | Location sharing |
| `social-contacts` | Contact list access |
| `money-purchasing` | In-app purchases |
| `money-gambling` | Gambling with real currency |

Each category has intensity levels: `none`, `mild`, `moderate`, `intense`.

Flathub already requires OARS metadata for all submitted apps. AppStream includes it. The metadata exists — we just need to consume it.

## Proposal

### Package-side: content ratings in `meta`

Packages declare their content rating in `meta.contentRating`, using the OARS schema:

```nix
{
  meta.contentRating = {
    violence-cartoon = "mild";
    violence-realistic = "none";
    language-profanity = "moderate";
    social-chat = "intense";
    money-purchasing = "mild";
    money-gambling = "none";
  };
}
```

For packages distributed via Flatpak or AppStream, this metadata can be extracted automatically from their existing OARS declarations. For nixpkgs packages, maintainers add it manually (or it defaults to unrated).

#### Shorthand presets

For convenience, packages can use presets that map to common rating board classifications:

```nix
{
  # Equivalent to setting individual OARS categories
  meta.contentRating.preset = "everyone";       # E / PEGI 3
  meta.contentRating.preset = "everyone-10";    # E10+ / PEGI 7
  meta.contentRating.preset = "teen";           # T / PEGI 12
  meta.contentRating.preset = "mature";         # M / PEGI 16
  meta.contentRating.preset = "adults-only";    # AO / PEGI 18
}
```

Presets expand to specific OARS values. Individual categories can override preset values:

```nix
{
  meta.contentRating = {
    preset = "teen";
    money-gambling = "intense";  # Override: this teen game has gambling
  };
}
```

#### Unrated packages

Packages without `meta.contentRating` are considered **unrated**. The content policy determines how unrated packages are handled — strict policies block them, permissive policies allow them.

### User-side: content policy in `nixpkgs.config`

The system-wide default content policy is declared in `nixpkgs.config`:

```nix
{
  nixpkgs.config.contentPolicy = {
    # Maximum allowed intensity per category
    violence-cartoon = "moderate";
    violence-realistic = "none";
    violence-fantasy = "mild";
    language-profanity = "mild";
    social-chat = "none";
    money-purchasing = "none";
    money-gambling = "none";

    # What to do with unrated packages
    allowUnrated = false;  # Block packages without content ratings
  };
}
```

#### Policy presets

Like package ratings, policies have presets:

```nix
{
  # Preset policies matching common parental control levels
  nixpkgs.config.contentPolicy.preset = "child";        # Very restrictive
  nixpkgs.config.contentPolicy.preset = "teen";          # Moderate
  nixpkgs.config.contentPolicy.preset = "unrestricted";  # Everything allowed (default)
}
```

#### Preset definitions

```nix
presets = {
  child = {
    violence-cartoon = "mild";
    violence-fantasy = "none";
    violence-realistic = "none";
    violence-bloodshed = "none";
    violence-sexual = "none";
    drugs-alcohol = "none";
    drugs-narcotics = "none";
    sex-nudity = "none";
    sex-themes = "none";
    sex-content = "none";
    language-profanity = "none";
    language-humor = "mild";
    social-chat = "none";
    social-info = "none";
    social-audio = "none";
    social-location = "none";
    money-purchasing = "none";
    money-gambling = "none";
    allowUnrated = false;
  };

  teen = {
    violence-cartoon = "intense";
    violence-fantasy = "moderate";
    violence-realistic = "mild";
    violence-bloodshed = "none";
    violence-sexual = "none";
    drugs-alcohol = "mild";
    drugs-narcotics = "none";
    sex-nudity = "mild";
    sex-themes = "mild";
    sex-content = "none";
    language-profanity = "moderate";
    language-humor = "moderate";
    social-chat = "moderate";
    social-info = "mild";
    social-audio = "moderate";
    social-location = "none";
    money-purchasing = "mild";
    money-gambling = "none";
    allowUnrated = false;
  };

  unrestricted = {
    # All categories set to "intense" (maximum)
    # allowUnrated = true
    # This is the default — no filtering
  };
};
```

### Enforcement

Content policy enforcement works exactly like `allowUnfree` — it filters the available package set. When a user's environment is assembled, each package is checked against their content policy. Packages that exceed the policy are excluded from the user's available set.

This runs alongside the existing license checks as a third independent filter:

```
Filter 1: Source availability (existing)
  allowClosedSource → excludes closed-source packages if false

Filter 2: Usage context (existing)
  usage.type → excludes packages whose licenses conflict with declared usage

Filter 3: Content policy (NEW)
  contentPolicy → excludes packages whose content ratings exceed the user's entitlements

  For each OARS category in the package's rating:
    Is the package's intensity ≤ the policy's maximum?
    → Yes: package remains available
    → No: package is excluded from the user's environment

  Is the package unrated?
    → allowUnrated = true: package remains available
    → allowUnrated = false: package is excluded
```

The user doesn't get a build error — the package is simply not in their set. If they try to add it to their configuration, they get the same kind of message as trying to use an unfree package without `allowUnfree`:

```
error: Package 'game-x' has content rating 'violence-realistic = intense'
       but user 'son' content policy allows maximum 'mild'.

       To allow this package, update the user's content policy:
         my.users.son.contentPolicy.violence-realistic = "intense";
```

Only the administrator can change the content policy — the user cannot override it.

### Integration with the token system

The cryptographic license token RFC (companion RFC) supports content entitlements as a new authorization type:

```
NixLicense/1
-----BEGIN NIX LICENSE TOKEN-----
Issuer: parent@family.local
LicenseeId: son
LicenseeName: Son

[authorizations]
content-violence-cartoon = mild
content-violence-realistic = none
content-language-profanity = mild
content-social-chat = none
content-money-purchasing = none
content-money-gambling = none
content-allow-unrated = false

[validity]
issued_at = 2025-01-01T00:00:00Z
expires_at = 2026-01-01T00:00:00Z

[signature]
algorithm = ed25519
public_key_id = parent@family.local/keys/2025
signature = <base64-encoded signature>
-----END NIX LICENSE TOKEN-----
```

The token is cryptographically signed by the parent/admin. The child user cannot modify it. Attenuation rules apply — a child can only make their own policy *more* restrictive (e.g., voluntarily blocking social features), never less.

### Per-user content policies (consumer module concern)

The base nix-license module operates at `nixpkgs.config` level — system-wide. Per-user content policies are the responsibility of consumer modules (e.g., mynixos) that have a user abstraction.

A consumer module would:

1. Accept per-user content policy declarations
2. Ensure packages available to that user respect their content policy
3. Enforce at the appropriate layer (package availability, desktop portal, application launcher)

Example of how a consumer module might expose this:

```nix
# This is NOT part of nix-license — it's how a consumer module uses it
users.son = {
  contentPolicy = {
    preset = "child";
    # Granular overrides
    violence-cartoon = "moderate";  # Allow a bit more cartoon violence
  };
};

users.parent = {
  contentPolicy = "unrestricted";
};
```

The consumer module would then wire this into the appropriate enforcement points:

Enforcement happens at **every layer** — defense in depth:

- **Build time**: The user's available package set is filtered by their content policy. A package that exceeds the user's entitlements is simply not part of their environment — the Nix evaluator excludes it, same as `allowUnfree = false` excludes unfree packages. If the user tries to add it to their configuration, the build fails with a clear message explaining which content category exceeded their policy.

- **Install time**: Even if a package somehow passes the build filter (e.g., added by another module), the package manager checks content policy before making it available in the user's profile. A package that doesn't meet the user's entitlements cannot be installed into their environment.

- **Runtime**: XDG desktop portal integration for Flatpak/AppStream apps that query content entitlements at runtime. Apps that perform their own content checks get a policy response (not a birth date) from the portal. Apps launched outside the desktop environment are blocked by a wrapper or systemd unit restriction if they exceed the user's policy.

This means enforcement is **proactive and layered**. The user cannot add a disallowed package to their configuration (build time), cannot install one into their profile (install time), and cannot run one that slipped through (runtime). Each layer catches what the previous one might miss.

The key distinction from blocklists: the admin doesn't enumerate forbidden packages. The admin sets a **policy**, and every package is automatically evaluated against it via its `meta.contentRating`. New packages, updated packages, everything — if it carries a content rating, the policy applies.

### Bridging to xdg-desktop-portal

For applications that query age verification through `xdg-desktop-portal` (the mechanism the systemd `birthDate` field is designed to support), the content policy can be exposed as a portal response:

Instead of:
```
Portal: "User's birth date is 2012-03-15"
App: (calculates age, decides what to do)
```

The portal responds with:
```
Portal: "User's content policy allows: violence-cartoon=mild, social-chat=none, ..."
App: (checks if its own rating fits within the policy)
```

Or even simpler — the portal just returns a boolean:
```
App: "Does this user's policy allow my content rating?"
Portal: "Yes" or "No"
```

The app doesn't learn the user's age, name, or any PII. It learns only whether its content is permitted — which is all it actually needs.

## Examples

### Parent setting up a family computer

```nix
{
  nixpkgs.config = {
    allowClosedSource = true;
    usage.type = "personal";

    # System-wide default: child-safe
    contentPolicy.preset = "child";
  };

  # Parent account: unrestricted (consumer module handles this)
  # Child account: inherits system default
}
```

### School computer lab

```nix
{
  nixpkgs.config = {
    allowClosedSource = false;  # FOSS only
    usage.type = "educational";

    contentPolicy = {
      preset = "child";
      allowUnrated = false;     # Only rated packages
      social-chat = "none";     # No chat apps
      money-purchasing = "none"; # No in-app purchases
    };
  };
}
```

### Corporate kiosk

```nix
{
  nixpkgs.config = {
    allowClosedSource = true;
    usage.type = "commercial";

    contentPolicy = {
      preset = "unrestricted";
      money-gambling = "none";   # No gambling apps on work machines
      social-chat = "moderate";  # Allow Slack/Teams level chat
    };
  };
}
```

### Gaming PC with per-user policies (via consumer module)

```nix
{
  # System allows everything
  nixpkgs.config.contentPolicy = "unrestricted";

  # Per-user restrictions via consumer module (e.g., mynixos)
  my.users.parent.contentPolicy = "unrestricted";

  my.users.teenager.contentPolicy = {
    preset = "teen";
    money-gambling = "none";
  };

  my.users.child.contentPolicy = {
    preset = "child";
    social-chat = "none";
  };
}
```

## Comparison with the systemd birthDate approach

| Concern | systemd `birthDate` | Content policy model |
|---------|---------------------|----------------------|
| PII storage | Yes (birth date) | No |
| Who decides access | Each app independently | Admin, once |
| Granularity | Binary (old enough / not) | Per-category, per-intensity |
| Enforcement | Advisory (app must check) | System-level (build/install/runtime) |
| Bypass resistance | User runs app from CLI | Cryptographic tokens, system enforcement |
| Metadata source | None (age is not content info) | OARS (already in Flathub/AppStream) |
| Multi-user | One policy per user (based on age) | Per-user entitlements |
| Corporate/school use | Irrelevant (age doesn't help) | Same model, different presets |
| Compliance | Stores PII to comply with privacy laws | Complies without storing PII |

## Drawbacks

**Requires content rating metadata.** Packages need `meta.contentRating` to be useful. Flathub apps already have OARS data, but most nixpkgs packages don't. Unrated packages are handled by the `allowUnrated` policy, but the system is most valuable when packages are rated.

**Rating accuracy.** Content ratings are subjective. Who decides if a text editor with a terminal has "social-chat = intense"? We rely on OARS as the standard and community consensus for edge cases. Packages can be overridden per-system.

**Enforcement gaps at runtime.** Build-time enforcement (package won't install) is strong. Runtime enforcement (app won't launch) requires integration with the desktop environment, application launcher, or a wrapper. This is implementation work beyond the policy model itself.

**Doesn't replace all age verification needs.** Some legal requirements specifically mandate age verification (proving someone is over 18), not just content filtering. This model doesn't satisfy those requirements — but it does provide a better *technical* solution for the actual goal (protecting minors from inappropriate content).

## Alternatives considered

**Store birth date like systemd.** Creates PII liability, delegates decisions to apps, provides no enforcement. Solves the legal letter but not the spirit.

**Per-app blocklists.** Simple but unscalable. Admin must know every app and classify it manually. Doesn't handle new apps, updates, or nuance (an app might be fine except for one feature).

**Age-based profiles (child/teen/adult).** Better than birth dates but still too coarse. A "teen" profile is a one-size-fits-all approximation of what's appropriate for a 13-year-old, a 15-year-old, and a 17-year-old. Content categories let the admin make precise decisions.

## Unresolved questions

**Enforcement layer.** Where exactly should content policy be enforced? Options include:
- Nix evaluation (package won't build for this user)
- Package manager (package won't install)
- Application launcher (app won't start)
- XDG desktop portal (app queries policy at runtime)
- All of the above

**OARS coverage.** OARS was designed for GUI applications. How do we rate CLI tools, libraries, or system services? Do they need ratings, or should `allowUnrated = true` cover them?

**Rating updates.** If a package's content changes (e.g., a game adds gambling mechanics in an update), how is the content rating updated? Who is responsible?

**Interaction with Flatpak.** Flatpak apps already have OARS metadata and their own parental controls via `xdg-desktop-portal`. How does this system interact with that? Should they share policy, or operate independently?

## Future possibilities

- **`nix content-report`:** Show all packages in your system closure with their content ratings vs. your policy
- **Automatic OARS import:** Tool to extract OARS data from AppStream/Flatpak metadata and generate `meta.contentRating`
- **Content policy portal:** XDG desktop portal backend that serves content policy decisions to applications, replacing the birth date approach
- **Parental controls UI:** Desktop application for managing per-user content policies without editing Nix configuration
- **Content policy inheritance:** Organizational hierarchies where department policies inherit from and attenuate company-wide policies

---

## Appendix: Quick Reference

### Package configuration

```nix
{
  meta.contentRating = {
    # OARS categories with intensity levels: "none" | "mild" | "moderate" | "intense"
    violence-cartoon = "mild";
    violence-fantasy = "moderate";
    violence-realistic = "none";
    violence-bloodshed = "none";
    violence-sexual = "none";
    drugs-alcohol = "none";
    drugs-narcotics = "none";
    drugs-tobacco = "none";
    sex-nudity = "none";
    sex-themes = "none";
    sex-content = "none";
    sex-appearance = "none";
    language-profanity = "mild";
    language-humor = "moderate";
    language-discrimination = "none";
    social-chat = "intense";
    social-info = "moderate";
    social-audio = "intense";
    social-location = "none";
    social-contacts = "none";
    money-purchasing = "mild";
    money-gambling = "none";

    # Or use a preset
    preset = "everyone" | "everyone-10" | "teen" | "mature" | "adults-only";
  };
}
```

### System-wide policy

```nix
{
  nixpkgs.config.contentPolicy = {
    # Per-category maximums
    violence-cartoon = "moderate";
    # ... other categories ...

    # Unrated package handling
    allowUnrated = true | false;

    # Or use a preset
    preset = "child" | "teen" | "unrestricted";
  };
}
```

### Per-user policy (consumer module, e.g., mynixos)

```nix
{
  my.users.<name>.contentPolicy = {
    preset = "child" | "teen" | "unrestricted";
    # Per-category overrides
    violence-cartoon = "moderate";
  };

  # Or shorthand
  my.users.<name>.contentPolicy = "unrestricted";
}
```

### Intensity ordering

```
none < mild < moderate < intense
```

A policy of `violence-cartoon = "moderate"` allows packages rated `none`, `mild`, or `moderate` for that category, but blocks `intense`.

### Content token authorizations

```
content-<oars-category> = none | mild | moderate | intense
content-allow-unrated = true | false
```

### Enforcement flow

```
User adds package to their environment
  │
  ▼
Package has meta.contentRating?
  ├── Yes: For each category:
  │     Package intensity ≤ User's policy maximum?
  │       ├── Yes: Package is available in user's environment
  │       └── No: Package is excluded from user's environment
  │              (same as allowUnfree = false excluding unfree packages)
  └── No (unrated):
        User's policy has allowUnrated?
          ├── Yes: Package is available
          └── No: Package is excluded
```

The user never sees a "build failure" — the package is simply not part of their available set. The admin controls the policy; packages carry their own ratings; the system connects the two automatically.
