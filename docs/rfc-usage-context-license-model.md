# RFC: Usage-Context-Based License Model

## Summary

Today, installing packages with restrictive licenses in NixOS requires setting `allowUnfree = true`. This single boolean conflates two unrelated questions:

1. **Is the source code available?** (open source vs. closed source)
2. **How am I allowed to use it?** (personal, commercial, redistribution)

This RFC proposes replacing `allowUnfree` with two separate configuration options that let users answer these questions independently. The change requires no modifications to the 80,000+ packages in nixpkgs—only updates to the central license definitions file.

## Background

### How license checking works today

When you try to install a package in NixOS, the package manager checks if the package's license is marked as "free." If it's not free, the build fails unless you've set `allowUnfree = true` in your configuration.

The license information lives in a single file called `lib/licenses.nix` in the nixpkgs repository. This file defines every license that packages can reference—MIT, GPL, Creative Commons variants, and so on. Each license has a `free` attribute that's either `true` or `false`.

Here's a simplified example of what that file looks like:

```nix
# lib/licenses.nix (simplified)
{
  mit = {
    fullName = "MIT License";
    free = true;
  };
  
  unfreeRedistributable = {
    fullName = "Unfree but redistributable";
    free = false;  # ← This is why NVIDIA drivers need allowUnfree
  };
  
  cc-by-nc-40 = {
    fullName = "Creative Commons Attribution-NonCommercial 4.0";
    free = false;  # ← This is why CC-BY-NC tools need allowUnfree
  };
}
```

When a package declares its license (e.g., `meta.license = lib.licenses.unfreeRedistributable` for NVIDIA drivers), and that license has `free = false`, you need `allowUnfree = true` to install it.

### The problem: one boolean, two different reasons

Look at those two `free = false` licenses above. They're marked unfree for completely different reasons:

- **NVIDIA drivers** (`unfreeRedistributable`): Unfree because the source code is closed. You can't see or modify the code. But you *can* use it commercially—NVIDIA doesn't restrict that.

- **CC-BY-NC tools** (`cc-by-nc-40`): Unfree because commercial use is prohibited. But the source code is often open—you can see and modify it.

Yet both require the same `allowUnfree = true` to install. This creates real problems:

| You want to... | What you set | What also gets allowed |
|----------------|--------------|------------------------|
| Install NVIDIA drivers | `allowUnfree = true` | CC-BY-NC software you might be violating commercially |
| Use CC-BY-NC tools personally | `allowUnfree = true` | Closed-source binaries you might not want |

A company that sets `allowUnfree = true` to get NVIDIA drivers has silently allowed software that prohibits commercial use. They might be violating licenses without knowing it.

## Proposal

### Replace one boolean with two independent settings

Instead of the single `allowUnfree = true`, users would configure two separate concerns in their NixOS configuration:

```nix
{
  nixpkgs.config = {
    # Question 1: Do you accept closed-source software?
    allowClosedSource = true;
    
    # Question 2: What's your usage context?
    usage = {
      type = "personal";      # or "commercial", "educational", "government"
      redistribution = false; # are you distributing builds to others?
      saas = false;           # are you running software-as-a-service?
      internal = true;        # is usage limited to your organization?
      military = false;       # military or defense use?
    };
  };
}
```

The `usage` block is a set of related settings that describe how you're using the software. Think of it as answering "what kind of user are you?" rather than "what kind of licenses do you allow?"

#### Complete list of usage options

| Option | Type | Description |
|--------|------|-------------|
| `type` | `"personal"` \| `"commercial"` \| `"educational"` \| `"government"` | Primary usage context |
| `redistribution` | boolean | Are you distributing builds to others outside your organization? |
| `saas` | boolean | Are you running software to provide services to third parties? |
| `internal` | boolean | Is usage limited to within your organization? (default: `true`) |
| `military` | boolean | Military, defense, or weapons-related use? |
| `research` | boolean | Academic or scientific research use? |
| `nonprofit` | boolean | Use by a registered nonprofit organization? |

Some usage types imply others:

```nix
# educational implies nonprofit (usually) and research
# government may or may not imply military
# saas implies commercial
# redistribution with commercial implies you might be selling it
```

These are independent choices. You might:

- Accept closed source but declare personal use (home user with NVIDIA)
- Reject closed source but declare commercial use (FOSS-only company)
- Accept closed source and declare commercial use (typical company)
- Reject closed source and declare personal use (FOSS purist)
- Accept closed source with educational use (university lab)

### How the new settings work

**`allowClosedSource`** controls whether you can install software where the source code isn't available. This is what most people *think* `allowUnfree` means. It covers:

- NVIDIA drivers
- Firmware blobs
- Proprietary applications distributed as binaries

**`usage`** declares your context so Nix can check for license conflicts:

- `type = "personal"` means you're not using software for business purposes
- `type = "commercial"` means you are (or might be)
- `redistribution = true` means you're distributing builds to others (like making a NixOS ISO)
- `saas = true` means you're running software to provide services to others (relevant for licenses like AGPL and SSPL)

### What changes in nixpkgs

The only code change is adding two new fields to the ~200 license definitions in `lib/licenses.nix`. These fields describe what each license restricts and requires:

```nix
# lib/licenses.nix with new fields
{
  cc-by-nc-40 = {
    fullName = "Creative Commons Attribution-NonCommercial 4.0";
    free = false;
    
    # NEW: What does this license prohibit?
    restrictions = {
      commercial = true;  # Can't use commercially
    };
    
    # NEW: What does this license require you to do?
    obligations = {};
  };
  
  # ... more examples below
}
```

#### Complete list of restrictions

Restrictions describe what a license prohibits. If your declared usage conflicts with a restriction, Nix blocks the build (or warns, during transition).

| Restriction | Meaning | Example licenses |
|-------------|---------|------------------|
| `commercial` | Prohibits commercial use | CC-BY-NC, many "free for personal use" licenses |
| `redistribution` | Prohibits distributing the software to others | Proprietary "unfree" licenses |
| `modification` | Prohibits modifying the source code | Some proprietary licenses, CC-ND |
| `military` | Prohibits military or weapons-related use | Some ethical licenses, Hippocratic License |
| `government` | Prohibits government use | Rare, but some activist-created licenses |
| `saas` | Prohibits running as a network service | Some commercial licenses |
| `derivativeWorks` | Prohibits creating derivative works | CC-ND variants |
| `benchmarking` | Prohibits publishing benchmarks | Some database/enterprise licenses |
| `reverseEngineering` | Prohibits reverse engineering | Many proprietary licenses |
| `sublicensing` | Prohibits granting sublicenses | Various commercial licenses |

#### Complete list of obligations

Obligations describe what a license requires you to do under certain circumstances. Nix can't enforce these—it can only warn you. You're responsible for actual compliance.

| Obligation | Meaning | Triggered by | Example licenses |
|------------|---------|--------------|------------------|
| `sourceDisclosure` | Must share source code | `saas`, `redistribution` | AGPL, SSPL, GPL (for redistribution) |
| `attribution` | Must give credit to authors | Any use | CC-BY, Apache 2.0, MIT |
| `copyleft` | Derivatives must use same license | `redistribution`, `derivativeWorks` | GPL, LGPL, MPL |
| `stateChanges` | Must document modifications | `modification`, `redistribution` | GPL, Apache 2.0 |
| `licenseInclusion` | Must include license text | `redistribution` | Most open source licenses |
| `noticePreservation` | Must preserve copyright notices | `redistribution` | Apache 2.0, BSD |
| `patentGrant` | Includes patent rights (informational) | — | Apache 2.0, GPL 3.0 |

#### Detailed license examples

Here's how various real licenses would be encoded:

```nix
# lib/licenses.nix

# Creative Commons NonCommercial - restricts commercial use
cc-by-nc-40 = {
  spdxId = "CC-BY-NC-4.0";
  fullName = "Creative Commons Attribution-NonCommercial 4.0";
  free = false;
  
  restrictions = {
    commercial = true;
  };
  
  obligations = {
    attribution = [ "any" ];  # Must attribute for any use
  };
};

# Creative Commons NoDerivatives - restricts modifications
cc-by-nd-40 = {
  spdxId = "CC-BY-ND-4.0";
  fullName = "Creative Commons Attribution-NoDerivatives 4.0";
  free = false;
  
  restrictions = {
    derivativeWorks = true;
    modification = true;
  };
  
  obligations = {
    attribution = [ "any" ];
  };
};

# AGPL - requires source disclosure for SaaS
agpl3Only = {
  spdxId = "AGPL-3.0-only";
  fullName = "GNU Affero General Public License v3.0";
  free = true;
  
  restrictions = {};  # Does NOT prohibit commercial use
  
  obligations = {
    sourceDisclosure = [ "saas" "redistribution" ];
    copyleft = [ "redistribution" "derivativeWorks" ];
    licenseInclusion = [ "redistribution" ];
  };
};

# SSPL - MongoDB's license, restricts SaaS
sspl = {
  spdxId = "SSPL-1.0";
  fullName = "Server Side Public License";
  free = false;
  
  restrictions = {};
  
  obligations = {
    # Must open source your ENTIRE stack if offering as a service
    sourceDisclosure = [ "saas" ];
  };
};

# GPL - copyleft for redistribution
gpl3Only = {
  spdxId = "GPL-3.0-only";
  fullName = "GNU General Public License v3.0";
  free = true;
  
  restrictions = {};
  
  obligations = {
    sourceDisclosure = [ "redistribution" ];
    copyleft = [ "redistribution" ];
    licenseInclusion = [ "redistribution" ];
  };
};

# MIT - minimal obligations
mit = {
  spdxId = "MIT";
  fullName = "MIT License";
  free = true;
  
  restrictions = {};
  
  obligations = {
    licenseInclusion = [ "redistribution" ];
    noticePreservation = [ "redistribution" ];
  };
};

# Apache 2.0 - permissive with patent grant
asl20 = {
  spdxId = "Apache-2.0";
  fullName = "Apache License 2.0";
  free = true;
  
  restrictions = {};
  
  obligations = {
    licenseInclusion = [ "redistribution" ];
    noticePreservation = [ "redistribution" ];
    stateChanges = [ "redistribution" ];  # Must note modifications
  };
  
  grants = {
    patent = true;  # Informational: includes patent grant
  };
};

# Hippocratic License - ethical restrictions
hippocratic = {
  fullName = "Hippocratic License";
  free = false;
  
  restrictions = {
    military = true;
    # Also restricts human rights violations, but that's hard to encode
  };
  
  obligations = {};
};

# Typical proprietary "unfree" license
unfree = {
  fullName = "Unfree";
  free = false;
  
  restrictions = {
    redistribution = true;
    modification = true;
    reverseEngineering = true;
  };
  
  obligations = {};
};

# Unfree but redistributable (e.g., NVIDIA drivers)
unfreeRedistributable = {
  fullName = "Unfree but redistributable";
  free = false;
  
  restrictions = {
    modification = true;
    reverseEngineering = true;
    # Note: redistribution is NOT restricted
  };
  
  obligations = {};
};

# Educational/academic use only
academicOnly = {
  fullName = "Academic/Educational Use Only";
  free = false;
  
  restrictions = {
    commercial = true;
    # Only educational/research use permitted
  };
  
  allowedUsageTypes = [ "educational" "research" ];
  
  obligations = {};
};
```

### No package changes required

This is important: none of the 80,000+ packages in nixpkgs need to change. Every package already declares its license via `meta.license = lib.licenses.something`. Once we add `restrictions` and `obligations` to those license definitions, every package automatically inherits the new metadata.

### What happens when you build

When you run `nixos-rebuild` or `nix build`, Nix performs several independent checks for each package:

**Check 1: Source availability**
```
Is this package closed-source?
  → Is the license one of: unfree, unfreeRedistributable, unfreeRedistributableFirmware?
  
Did you allow closed source?
  → Is allowClosedSource = true?
  
If closed-source and not allowed → Error
```

**Check 2: Usage type restrictions**
```
Does this license restrict certain usage types?

Commercial restriction:
  license.restrictions.commercial = true AND usage.type = "commercial"
  → Error: "License prohibits commercial use"

Military restriction:
  license.restrictions.military = true AND usage.military = true
  → Error: "License prohibits military use"

Allowed usage types (if specified):
  license.allowedUsageTypes = [ "educational" "research" ]
  AND usage.type NOT IN allowedUsageTypes
  → Error: "License only permits educational/research use"
```

**Check 3: Activity restrictions**
```
Redistribution restriction:
  license.restrictions.redistribution = true AND usage.redistribution = true
  → Error: "License prohibits redistribution"

SaaS restriction:
  license.restrictions.saas = true AND usage.saas = true
  → Error: "License prohibits running as a service"

Modification restriction:
  license.restrictions.modification = true AND you're patching the package
  → Warning: "License prohibits modification"
```

**Check 4: Obligations (warnings only)**
```
Source disclosure obligation:
  "saas" IN license.obligations.sourceDisclosure AND usage.saas = true
  → Warning: "You must make source available to users of your service"

  "redistribution" IN license.obligations.sourceDisclosure AND usage.redistribution = true
  → Warning: "You must provide source code with redistributed binaries"

Copyleft obligation:
  license.obligations.copyleft AND usage.redistribution = true
  → Warning: "Derivative works must use the same license"

Attribution obligation:
  license.obligations.attribution
  → Info: "Attribution required - see license for details"
```

These checks are independent. A package can fail some and pass others:

- Pass the source check but fail the usage check (open-source CC-BY-NC when you're a business)
- Fail the source check but pass the usage check (NVIDIA when you don't allow closed source)
- Pass both (MIT, Apache, GPL for any use)
- Fail both (hypothetical closed-source non-commercial package)

### Example: What different users would configure

**Home user who wants NVIDIA drivers:**
```nix
{
  nixpkgs.config = {
    allowClosedSource = true;  # Yes to NVIDIA
    usage.type = "personal";   # I'm not a business
  };
}
```

| Package | Result | Why |
|---------|--------|-----|
| NVIDIA drivers | ✓ | Closed-source allowed, no commercial restriction |
| CC-BY-NC tool | ✓ | Personal use is permitted by the license |
| MIT library | ✓ | No restrictions |

**Company that needs NVIDIA:**
```nix
{
  nixpkgs.config = {
    allowClosedSource = true;  # Yes to NVIDIA
    usage.type = "commercial"; # We're a business
  };
}
```

| Package | Result | Why |
|---------|--------|-----|
| NVIDIA drivers | ✓ | Closed-source allowed, NVIDIA permits commercial use |
| CC-BY-NC tool | ✗ | License prohibits commercial use |
| MIT library | ✓ | No restrictions |

The company now *knows* about the CC-BY-NC conflict instead of accidentally violating the license.

**University research lab:**
```nix
{
  nixpkgs.config = {
    allowClosedSource = true;   # Need some proprietary research tools
    usage = {
      type = "educational";
      research = true;
      nonprofit = true;
    };
  };
}
```

| Package | Result | Why |
|---------|--------|-----|
| NVIDIA drivers | ✓ | Closed-source allowed |
| CC-BY-NC tool | ✓ | Educational/research is non-commercial |
| Academic-only software | ✓ | Educational use explicitly permitted |
| MIT library | ✓ | No restrictions |

**Government agency (civilian):**
```nix
{
  nixpkgs.config = {
    allowClosedSource = true;
    usage = {
      type = "government";
      military = false;        # Civilian agency
    };
  };
}
```

| Package | Result | Why |
|---------|--------|-----|
| NVIDIA drivers | ✓ | No government restriction |
| Software with no-government clause | ✗ | License prohibits government use |
| Hippocratic-licensed tool | ✓ | Non-military government OK |
| MIT library | ✓ | No restrictions |

**Defense contractor:**
```nix
{
  nixpkgs.config = {
    allowClosedSource = true;
    usage = {
      type = "commercial";     # We're a business
      military = true;         # Defense work
    };
  };
}
```

| Package | Result | Why |
|---------|--------|-----|
| NVIDIA drivers | ✓ | No military restriction |
| Hippocratic-licensed tool | ✗ | License prohibits military use |
| CC-BY-NC tool | ✗ | Commercial use prohibited |
| MIT library | ✓ | No restrictions |

**FOSS-only company:**
```nix
{
  nixpkgs.config = {
    allowClosedSource = false; # Open source only
    usage.type = "commercial"; # We're a business
  };
}
```

| Package | Result | Why |
|---------|--------|-----|
| NVIDIA drivers | ✗ | Closed source not allowed |
| CC-BY-NC tool | ✗ | Commercial use restricted |
| AGPL library | ✓ (with warning) | Open source, commercial OK, but warns about source disclosure |
| MIT library | ✓ | No restrictions |

**SaaS company using MongoDB:**
```nix
{
  nixpkgs.config = {
    allowClosedSource = true;
    usage = {
      type = "commercial";
      saas = true;             # We offer services to customers
    };
  };
}
```

| Package | Result | Why |
|---------|--------|-----|
| MongoDB (SSPL) | ⚠ | Warning: Must open source your entire service stack |
| AGPL web framework | ⚠ | Warning: Must disclose source to users |
| MIT library | ✓ | No restrictions |

**Someone building a NixOS ISO for distribution:**
```nix
{
  nixpkgs.config = {
    allowClosedSource = false;    # Can't redistribute closed source
    usage = {
      type = "personal";
      redistribution = true;      # I'm distributing this ISO
    };
  };
}
```

| Package | Result | Why |
|---------|--------|-----|
| NVIDIA drivers | ✗ | Closed source, can't include in ISO |
| CC-BY-NC tool | ✓ | Non-commercial redistribution is fine |
| unfree (non-redistributable) | ✗ | License prohibits redistribution |
| GPL library | ✓ (with info) | Must include source or offer to provide it |

**Nonprofit organization:**
```nix
{
  nixpkgs.config = {
    allowClosedSource = true;
    usage = {
      type = "commercial";   # Nonprofits can still be "commercial" legally
      nonprofit = true;      # But we're a registered nonprofit
    };
  };
}
```

| Package | Result | Why |
|---------|--------|-----|
| Software with nonprofit discount | ✓ | Nonprofit status recognized |
| CC-BY-NC tool | Depends | Some NC licenses allow nonprofit use, some don't |
| MIT library | ✓ | No restrictions |

### Handling commercial licenses you've purchased

Sometimes you have a commercial license for software that would otherwise be restricted. For example, a company might purchase a commercial license for a tool that's normally CC-BY-NC. You can declare this:

```nix
{
  nixpkgs.config = {
    usage.type = "commercial";
    
    # "I bought a commercial license for this NC-licensed package"
    licenses."some-nc-tool" = {
      license = "commercial";
      licenseId = "LIC-2024-XXXXX";  # For your records
      expiresAt = "2025-06-15";      # Nix can warn before expiry
    };
  };
}
```

This tells Nix: "Yes, I know this package has restrictions, but I have a separate license that permits my use." Nix trusts this declaration—it's documentation, not cryptographic verification.

For cryptographic verification of commercial licenses (where Nix actually validates a signed token from the vendor), see the companion RFC on license tokens.

### Migration path

We're not breaking anyone's existing configuration. The transition happens gradually:

**NixOS 25.05 (introduction):** New options available. `allowUnfree = true` still works exactly as before, but prints a notice explaining the new options. License conflicts produce warnings, not errors.

```
$ nixos-rebuild switch
note: 'allowUnfree' is deprecated. Consider using:

  nixpkgs.config = {
    allowClosedSource = true;
    usage.type = "personal";  # or "commercial"
  };

warning: Package 'some-tool' (CC-BY-NC-4.0) restricts commercial use.
         Your effective usage context: commercial (assumed from allowUnfree)
         
         If you're using this personally, set: usage.type = "personal"
         If you have a commercial license, add it to: nixpkgs.config.licenses
```

**NixOS 25.11 (opt-in enforcement):** Users can enable strict mode with `licenseEnforcement = "enforce"`. Warnings become errors.

**NixOS 26.05 (default enforcement):** Enforcement is the default. `allowUnfree` still works but is fully deprecated.

When you have `allowUnfree = true`, it internally translates to:
```nix
{
  allowClosedSource = true;
  usage.type = "commercial";  # Most permissive assumption to avoid breaking builds
  licenseEnforcement = "warn";
}
```

This preserves current behavior while nudging users toward the more precise model.

## Drawbacks

**More configuration to understand.** Two settings instead of one boolean. We mitigate this with sensible defaults, clear error messages that explain what to set, and presets for common scenarios.

**License metadata work.** Someone needs to add `restrictions` and `obligations` to ~200 licenses in `lib/licenses.nix`. This is mechanical work—the information comes directly from the license text and SPDX definitions—but it's still effort.

**Some licenses are ambiguous.** Not every license has crystal-clear terms. We encode best-effort interpretations based on common understanding and legal consensus. Edge cases default to permissive (allow rather than block) since Nix shouldn't be making legal determinations.

**Migration friction.** Users with `allowUnfree = true` will see deprecation warnings. The 18-month timeline makes this gradual, and the warnings include specific guidance.

## Alternatives considered

**Just rename `allowUnfree` to `allowClosedSource`:** Clearer name, but still doesn't solve the core problem. Companies could still accidentally allow CC-BY-NC software because we haven't separated the two concerns.

**Add `allowNonCommercial` as a second boolean:** This asks "do you allow NC licenses?" instead of "are you commercial?" It's backwards—users shouldn't need to understand license categories. They should just declare their own context and let Nix figure out what's compatible.

**Do nothing:** Users keep guessing and potentially violating licenses without knowing it.

## Unresolved questions

**Dual-licensed packages.** Some packages offer multiple licenses (e.g., "GPL or commercial at your choice"). We need semantics for expressing "this package is available under license A OR license B" and letting users pick.

**Transitive obligations.** If package A (MIT) depends on package B (AGPL), the combined work may have AGPL obligations. Should Nix trace this through the dependency graph and warn accordingly?

**Defaults.** Should `allowClosedSource` default to `true` (matching current `allowUnfree` behavior, less friction) or `false` (encouraging open source, more friction but principled)?

## Future possibilities

- **`nix license-report`:** Show all packages in your system closure vs. your declared usage context
- **`nix license-check`:** Analyze transitive license obligations through the dependency graph
- **Cryptographic license tokens:** Zero-trust verification of commercial licenses where Nix validates a signed token from the vendor (separate RFC)
- **SBOM export:** Include license compliance information in software bills of materials for auditing

---

## Appendix: Quick Reference

### User configuration options

```nix
{
  nixpkgs.config = {
    # Accept closed-source packages?
    allowClosedSource = true | false;
    
    # Your usage context
    usage = {
      type = "personal" | "commercial" | "educational" | "government";
      redistribution = true | false;
      saas = true | false;
      internal = true | false;
      military = true | false;
      research = true | false;
      nonprofit = true | false;
    };
    
    # Enforcement level during transition
    licenseEnforcement = "warn" | "enforce";
    
    # Per-package license overrides
    licenses."package-name" = {
      license = "commercial";
      licenseId = "...";      # Optional documentation
      expiresAt = "...";      # Optional, enables expiry warnings
      tokenFile = ./...;      # For cryptographic validation (see companion RFC)
    };
  };
}
```

### License restrictions (in `lib/licenses.nix`)

| Restriction | Meaning | Blocks when... |
|-------------|---------|----------------|
| `commercial` | Prohibits commercial use | `usage.type = "commercial"` |
| `military` | Prohibits military/defense use | `usage.military = true` |
| `government` | Prohibits government use | `usage.type = "government"` |
| `redistribution` | Prohibits distributing the software | `usage.redistribution = true` |
| `saas` | Prohibits running as a service | `usage.saas = true` |
| `modification` | Prohibits modifying the code | Package has patches |
| `derivativeWorks` | Prohibits creating derivatives | — |
| `benchmarking` | Prohibits publishing benchmarks | — |
| `reverseEngineering` | Prohibits reverse engineering | — |

### License obligations (in `lib/licenses.nix`)

| Obligation | Meaning | Warns when... |
|------------|---------|---------------|
| `sourceDisclosure` | Must share source code | `usage.saas` or `usage.redistribution` |
| `attribution` | Must credit authors | Any use |
| `copyleft` | Derivatives must use same license | `usage.redistribution` |
| `stateChanges` | Must document modifications | `usage.redistribution` with changes |
| `licenseInclusion` | Must include license text | `usage.redistribution` |
| `noticePreservation` | Must preserve copyright notices | `usage.redistribution` |
