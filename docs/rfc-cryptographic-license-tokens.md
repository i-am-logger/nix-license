# RFC: Cryptographic License Tokens for Nix

## Summary

The "Usage-Context-Based License Model" RFC lets users declare commercial license overrides like this:

```nix
nixpkgs.config.licenses."vendor-sdk".license = "commercial";
```

But this is just a declaration—Nix trusts you. This companion RFC proposes a cryptographic token format that lets Nix actually *verify* that you have a valid license from the vendor, without requiring network access during builds.

## Background

### The trust problem

In the base license model, when you say "I have a commercial license," Nix believes you:

```nix
{
  nixpkgs.config.licenses."expensive-tool" = {
    license = "commercial";
    licenseId = "LIC-2024-XXXXX";  # Nix doesn't check this
  };
}
```

This works for personal use and small teams, but it's insufficient for:

- **Vendors** who want real enforcement, not an honor system
- **Organizations** that need audit trails proving they're actually licensed
- **Build systems** that should fail when licenses are expired or invalid

### Why not just check online?

Nix builds happen inside a sandbox with no network access. This is fundamental to Nix's reproducibility guarantees—a build that worked yesterday should work the same way today, regardless of network conditions or whether a license server is up.

We can't add "call the vendor's license server" to the build process. But we *can* verify a cryptographic token that proves you had a valid license when you obtained the token.

### How this works conceptually

1. You purchase a license from a vendor
2. The vendor gives you a signed token (a file) proving your license
3. You put this file in your NixOS configuration
4. When Nix builds, it verifies the token's signature and checks if it's expired
5. If valid, the build proceeds. If invalid or expired, the build fails.

The token is self-contained proof. No network calls needed.

## Proposal

### Token format

A license token is a text file containing claims (who licensed what, for how long) and a cryptographic signature from the vendor:

```
NixLicense/1
-----BEGIN NIX LICENSE TOKEN-----
Issuer: vendor.example.com
LicenseeId: org-12345
LicenseeName: Acme Corp
Package: vendor-sdk
Version: >= 2.0, < 3.0

[authorizations]
# What usage types are permitted
commercial = true
educational = true
government = true
military = false

# What activities are permitted
redistribution = false
saas = true
modification = true

# Quantity limits
seats = 25
machines = *

[validity]
issued_at = 2024-06-15T00:00:00Z
expires_at = 2025-06-15T00:00:00Z

[signature]
algorithm = ed25519
public_key_id = vendor.example.com/keys/2024
signature = <base64-encoded signature>
-----END NIX LICENSE TOKEN-----
```

The signature covers all the claims above it. If anyone modifies the licensee name, expiry date, or any other field, the signature becomes invalid.

### What the token contains

**Issuer and licensee:** Who issued the license and who it's for. Useful for audit trails.

**Package and version:** What software this license covers. A token for `vendor-sdk >= 2.0` won't work for version 1.x or a different package.

**Authorizations:** What this license permits. The authorizations match the `usage` settings from the base RFC:

| Authorization | Meaning |
|---------------|---------|
| `commercial` | Permits commercial use |
| `educational` | Permits educational/academic use |
| `government` | Permits government use |
| `military` | Permits military/defense use |
| `redistribution` | Permits distributing the software |
| `saas` | Permits running as a service |
| `modification` | Permits modifying the software |
| `seats` | Number of users/seats allowed |
| `machines` | Number of machines allowed (`*` = unlimited) |

**Validity period:** When the license starts and expires. Nix checks this against the current time.

**Signature:** Cryptographic proof that the vendor issued this token with these exact claims.

### Verification flow

Here's what happens when you build a package that requires a license token:

```
┌─────────────────────────────────────────────────────────────────┐
│ BEFORE NIX RUNS (your responsibility)                           │
│                                                                 │
│  1. Purchase license from vendor                                │
│  2. Download token file from vendor portal                      │
│  3. Store token somewhere Nix can read it:                      │
│     - In your repo: ./secrets/vendor-sdk.token                  │
│     - Via secrets manager: /run/secrets/vendor-sdk              │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│ NIX EVALUATION (pure, no network access)                        │
│                                                                 │
│  1. Load token from path in your config                         │
│                                                                 │
│  2. Verify signature                                            │
│     - Token claims the signature is from vendor.example.com     │
│     - Package definition includes vendor's public key           │
│     - Nix checks: does the signature match the claims?          │
│     - If no: "Invalid license token signature" → build fails    │
│                                                                 │
│  3. Check authorizations match your declared usage              │
│     - Token says: commercial = true, military = false           │
│     - Your config says: usage.type = "commercial"               │
│     - Your config says: usage.military = false                  │
│     - All match? Proceed.                                       │
│     - Mismatch? Fail with clear error:                          │
│       "Token does not authorize military use"                   │
│                                                                 │
│  4. Check expiry                                                │
│     - Token says: expires_at = 2025-06-15                       │
│     - Current time: 2024-12-03                                  │
│     - Not expired? Proceed. Expired? Fail.                      │
│                                                                 │
│  5. All checks pass → build proceeds                            │
└─────────────────────────────────────────────────────────────────┘
```

### What Nix does and doesn't do

**Nix does:**
- Verify the cryptographic signature is valid
- Check the token hasn't expired
- Confirm the token's authorizations match your declared usage
- Fail builds when tokens are invalid, expired, or insufficient

**Nix does not:**
- Fetch tokens for you (you get them from the vendor however they provide them)
- Check revocation online (tokens have expiry dates; short expiry = frequent renewal = quasi-revocation)
- Count seats at runtime (vendors enforce seat limits when issuing tokens)
- Prevent you from lying about the current time (but build logs make this detectable for audits)

### User configuration

To use a license token, reference it in your NixOS configuration:

```nix
{
  nixpkgs.config = {
    usage.type = "commercial";
    
    licenses."vendor-sdk" = {
      license = "commercial";
      
      # Path to the token file
      tokenFile = ./secrets/vendor-sdk.token;
    };
  };
}
```

Or if your token is small, you can inline it:

```nix
{
  nixpkgs.config.licenses."vendor-sdk" = {
    license = "commercial";
    
    token = ''
      NixLicense/1
      -----BEGIN NIX LICENSE TOKEN-----
      Issuer: vendor.example.com
      ...
      -----END NIX LICENSE TOKEN-----
    '';
  };
}
```

### How packages declare they need verification

Package maintainers (or vendors packaging their own software) declare the vendor's public key in the package definition:

```nix
{ lib, stdenv, fetchurl, nixLicenseLib, commercialLicense ? null }:

let
  # The vendor's public keys for verifying license tokens
  # Multiple keys supported for key rotation
  vendorPublicKeys = [
    "ed25519:MCowBQYDK2VwAyEA..."  # 2024 key
    "ed25519:MCowBQYDK2VwAyEA..."  # 2023 key (still accepted)
  ];
  
  # Validate the token (this is a pure computation, no network)
  validatedLicense = nixLicenseLib.validateToken {
    token = commercialLicense;
    publicKeys = vendorPublicKeys;
    requiredClaims = {
      package = "vendor-sdk";
      versionMatch = version;
    };
  };

in stdenv.mkDerivation {
  pname = "vendor-sdk";
  version = "2.5.0";
  
  # If commercialLicense is null or invalid, this fails at eval time
  # with a clear error message
  meta.license = lib.licenses.unfree;
  
  # Use validated info from the token
  postInstall = ''
    echo "Licensed to: ${validatedLicense.licensee}" > $out/LICENSE_INFO
    echo "Expires: ${validatedLicense.expiresAt}" >> $out/LICENSE_INFO
  '';
}
```

If you try to build this package without a valid token, you get a clear error:

```
error: Package 'vendor-sdk' requires a commercial license token.

       1. Obtain a license from https://vendor.example.com/licensing
       2. Download your license token
       3. Add to your configuration:
       
          nixpkgs.config.licenses."vendor-sdk" = {
            license = "commercial";
            tokenFile = /path/to/your/token;
          };
```

### Organizational token attenuation

Large organizations often have a master license (say, 500 seats) that IT manages. They want to give teams restricted sub-licenses without sharing the master token.

Token attenuation lets you derive a restricted token from a more permissive one:

```nix
let
  # IT has the master token with full permissions
  # Master token authorizations:
  #   commercial = true, educational = true, government = true
  #   military = true (defense contractor)
  #   seats = 500, machines = *
  #   redistribution = false, saas = true
  masterToken = builtins.readFile /run/secrets/master-license.token;
  
  # Derive a restricted token for the civilian projects team
  civilianTeamToken = nixLicenseLib.attenuateToken {
    token = masterToken;
    
    # Can only ADD restrictions, never remove them
    # If master says military = true, you can set military = false
    # If master says military = false, you cannot set military = true
    attenuations = {
      seats = 50;                           # 50 of the 500
      military = false;                     # This team does civilian work only
      machine_pattern = "civilian-*";       # Only machines with this prefix
      expires_at = "2024-12-31T00:00:00Z";  # Shorter validity than master
    };
    
    # IT's key signs the attenuation (creates audit trail)
    signingKey = /run/secrets/it-signing-key;
  };
  
  # Derive another restricted token for a research partnership
  researchPartnerToken = nixLicenseLib.attenuateToken {
    token = masterToken;
    
    attenuations = {
      seats = 10;
      commercial = false;                   # Research only, not for production
      educational = true;
      redistribution = false;
      saas = false;
      expires_at = "2024-06-30T00:00:00Z";  # Short-term partnership
    };
    
    signingKey = /run/secrets/it-signing-key;
  };
in
  # These derived tokens can be distributed to teams
  # They're cryptographically chained to the master token
  # Vendor can verify the chain if needed for audits
```

The derived token is cryptographically linked to the master. You can only make it *more* restrictive, never less. This lets organizations delegate license management without losing control.

**Attenuation rules:**
- Boolean `true` in master → can attenuate to `false`
- Boolean `false` in master → cannot attenuate to `true`
- Numeric value → can only decrease (seats: 500 → 50, not 500 → 600)
- Date → can only make earlier (expire sooner)
- New restrictions can be added (machine_pattern) but not removed

### Expiry warnings

Nix warns you before licenses expire:

```
$ nixos-rebuild switch
warning: License for 'vendor-sdk' expires in 23 days (2025-06-15)
         Renew at: https://vendor.example.com/licenses
```

### Integrating with secrets managers

License tokens are often sensitive. Here's how to integrate with common NixOS secrets management tools:

**With sops-nix:**
```nix
{
  # Decrypt the token at boot
  sops.secrets.vendor-license = {
    sopsFile = ./secrets/licenses.yaml;
    path = "/run/secrets/vendor-license";
  };
  
  # Reference the decrypted path
  nixpkgs.config.licenses."vendor-sdk" = {
    license = "commercial";
    tokenFile = config.sops.secrets.vendor-license.path;
  };
}
```

**With agenix:**
```nix
{
  age.secrets.vendor-license.file = ./secrets/vendor-license.age;
  
  nixpkgs.config.licenses."vendor-sdk" = {
    license = "commercial";
    tokenFile = config.age.secrets.vendor-license.path;
  };
}
```

### CI/CD integration

In CI/CD pipelines, fetch the token before running Nix:

```yaml
# GitHub Actions example
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Fetch license token from secrets manager
        run: |
          # However your org manages secrets
          vault read -field=token secret/licenses/vendor-sdk \
            > ./secrets/vendor-sdk.token
      
      - name: Build
        run: nix build
```

No special Nix tooling needed. The token is just a file that exists before Nix runs.

### Vendor tooling

For vendors who want to issue license tokens, we'd provide a CLI tool:

```bash
# Generate a signing keypair (do this once, protect the private key)
$ nix-license keygen \
    --vendor vendor.example.com \
    --output vendor-keys/

# Issue a license token with full options
$ nix-license issue \
    --signing-key vendor-keys/private.pem \
    --licensee "Acme Corp" \
    --licensee-id "org-12345" \
    --package "vendor-sdk" \
    --version ">= 2.0" \
    \
    # Usage type authorizations
    --commercial true \
    --educational true \
    --government true \
    --military false \
    \
    # Activity authorizations
    --redistribution false \
    --saas true \
    --modification true \
    \
    # Quantity limits
    --seats 25 \
    --machines unlimited \
    \
    # Validity
    --expires "2025-06-15" \
    \
    --output acme-corp-license.token

# Example: Issue an educational-only license
$ nix-license issue \
    --signing-key vendor-keys/private.pem \
    --licensee "State University" \
    --licensee-id "edu-67890" \
    --package "vendor-sdk" \
    --version ">= 2.0" \
    --commercial false \
    --educational true \
    --government false \
    --military false \
    --redistribution false \
    --saas false \
    --seats unlimited \
    --machines unlimited \
    --expires "2026-08-31" \
    --output state-university-license.token

# Publish your public key so packages can verify tokens
# (This would go in your package definition or a central registry)
$ cat vendor-keys/public.pem
```

### Fallback: Not every package needs this

Cryptographic tokens are the high-security option. The system supports a spectrum:

```nix
# Level 1: Trust-based declaration (simplest, no verification)
nixpkgs.config.licenses."tool-a".license = "commercial";

# Level 2: License key that the package validates internally
# (Package has its own validation logic, common for existing commercial software)
nixpkgs.config.licenses."tool-b" = {
  license = "commercial";
  key = "XXXX-XXXX-XXXX-XXXX";
};

# Level 3: Cryptographic token (full zero-trust verification by Nix)
nixpkgs.config.licenses."tool-c" = {
  license = "commercial";
  tokenFile = ./license.token;
};
```

Vendors and package maintainers choose the appropriate level. Most open-source packages need nothing. Commercial packages might use level 2 (their existing licensing) or upgrade to level 3 for tighter integration with Nix.

## Examples

### Simple commercial package

```nix
{
  nixpkgs.config = {
    usage.type = "commercial";
    
    licenses."vendor-sdk" = {
      license = "commercial";
      tokenFile = ./secrets/vendor-sdk.token;
    };
  };
}
```

Build succeeds if the token is valid, authorizes commercial use, and isn't expired.

### University with educational license

```nix
{
  nixpkgs.config = {
    usage = {
      type = "educational";
      research = true;
      nonprofit = true;
    };
    
    licenses."expensive-research-tool" = {
      license = "commercial";
      tokenFile = ./secrets/research-tool.token;
      # Token was issued with: educational = true, commercial = false
    };
  };
}
```

Build succeeds because declared usage (educational) matches token authorizations.

### Defense contractor with restricted token

```nix
{
  nixpkgs.config = {
    usage = {
      type = "commercial";
      military = true;
    };
    
    licenses."simulation-software" = {
      license = "commercial";
      tokenFile = ./secrets/simulation.token;
      # Token was issued with: military = true, commercial = true
    };
  };
}
```

Build succeeds because token explicitly authorizes military use.

### SaaS company

```nix
{
  nixpkgs.config = {
    usage = {
      type = "commercial";
      saas = true;
    };
    
    licenses."database-engine" = {
      license = "commercial";
      tokenFile = ./secrets/database.token;
      # Token was issued with: commercial = true, saas = true
    };
  };
}
```

Build succeeds because token authorizes SaaS use. Without `saas = true` in the token, it would fail.

### Company-wide license management

```nix
# /etc/nixos/company-licenses.nix
# Managed by IT, imported by all company machines
{
  nixpkgs.config.licenses = {
    "jetbrains.idea-ultimate" = {
      license = "commercial";
      tokenFile = "/run/secrets/jetbrains.token";
    };
    
    "vendor-sdk" = {
      license = "commercial";
      tokenFile = "/run/secrets/vendor-sdk.token";
    };
    
    "simulation-software" = {
      license = "commercial";
      tokenFile = "/run/secrets/simulation.token";
    };
  };
}

# Individual machine configs just import this
{ imports = [ ./company-licenses.nix ]; }
```

IT manages the tokens centrally. Individual machines inherit the configuration.

### Team-specific attenuated tokens

```nix
# /etc/nixos/dev-team-licenses.nix
# Derived from company master tokens with restrictions
{
  nixpkgs.config = {
    usage = {
      type = "commercial";
      military = false;  # Dev team only works on civilian projects
    };
    
    licenses = {
      "vendor-sdk" = {
        license = "commercial";
        # This token was attenuated from the master:
        # - seats: 500 → 50
        # - military: true → false
        # - expires_at: 2025-12-31 → 2024-12-31
        tokenFile = "/run/secrets/vendor-sdk-dev-team.token";
      };
    };
  };
}
```

### Air-gapped environment

```nix
{
  nixpkgs.config.licenses."vendor-sdk" = {
    license = "commercial";
    tokenFile = ./license.token;
    
    # Token was issued with 1-year validity
    # In air-gapped environments, this is fine
    # For connected environments, vendors might issue shorter-lived tokens
  };
}
```

Since verification is entirely offline, air-gapped environments work identically to connected ones.

## Drawbacks

**Requires vendor adoption.** The benefits only materialize when vendors issue tokens in this format. Until then, packages fall back to trust-based declarations or their existing licensing mechanisms.

**Adds complexity.** Cryptographic tokens are harder to understand than "I have a license." We mitigate this with clear error messages, documentation, and the fallback spectrum (you can always use simpler approaches).

**Token management overhead.** Organizations must fetch, store, and rotate tokens. Integration with existing secrets managers helps, but it's still more moving parts than a simple boolean.

**No runtime enforcement.** Nix validates at build time. If a package needs runtime seat counting or floating licenses, that requires separate mechanisms outside of Nix.

**Time-based expiry can be circumvented.** A user could lie about the current time to bypass expiry checks. However, build logs record when builds actually happened, making this detectable in audits. We make cheating *detectable*, not impossible.

## Alternatives considered

**Online license server calls during build:** Would require network access in the sandbox, breaking Nix's reproducibility model. Also fails in air-gapped environments and when servers are down.

**Let packages validate licenses internally:** This is the status quo for most commercial software. It works but provides no standardization, inconsistent user experience, and no organizational tooling.

**Trust-based declarations only:** Insufficient for vendors wanting enforcement or organizations needing audit trails. The base RFC supports this; cryptographic tokens are an upgrade path.

## Prior art

- **Biscuit:** Cryptographic authorization tokens with attenuation support. Well-specified with implementations in Rust, Go, and JavaScript. ([biscuitsec.org](https://biscuitsec.org/))
- **Macaroons:** Google's decentralized authorization credentials with contextual caveats. Academic foundation for Biscuit.
- **JetBrains licensing:** Uses signed offline license files, conceptually similar to what we're proposing.
- **FlexLM/RLM:** Traditional floating license servers. Network-dependent, not compatible with Nix's build model.

## Unresolved questions

**Token format:** Should we adopt Biscuit directly (mature, existing implementations) or define a Nix-specific format (simpler, tailored to our needs)?

**Public key distribution:** Should vendor public keys be:
- Hardcoded in package definitions?
- Fetched from well-known URLs (but when—before the build)?
- Stored in a registry within nixpkgs?

**Revocation beyond expiry:** Is expiry sufficient, or do we need an optional online revocation check that happens *before* the sandbox (not during the build)?

**Datalog policies:** Biscuit supports rich authorization policies via Datalog. Do we need this complexity, or is simple claim matching sufficient?

## Future possibilities

- **Vendor public key registry:** Curated list of vendor keys in nixpkgs for easier verification
- **`nix-license renew` command:** Automate token renewal from vendor APIs
- **License compliance dashboard:** Web UI showing organization-wide license status
- **Floating license proxy:** A daemon that manages runtime seat allocation for packages that need it (outside of Nix's build system)

---

## Appendix: Quick Reference

### Token structure

```
NixLicense/1
-----BEGIN NIX LICENSE TOKEN-----
Issuer: <vendor domain>
LicenseeId: <unique identifier>
LicenseeName: <human-readable name>
Package: <package name>
Version: <version constraint>

[authorizations]
commercial = true | false
educational = true | false
government = true | false
military = true | false
redistribution = true | false
saas = true | false
modification = true | false
seats = <number> | *
machines = <number> | *

[validity]
issued_at = <ISO 8601 datetime>
expires_at = <ISO 8601 datetime>

[attenuations]
# Optional: further restrictions added by organization
<key> = <value>

[signature]
algorithm = ed25519
public_key_id = <key identifier>
signature = <base64-encoded signature>
-----END NIX LICENSE TOKEN-----
```

### User configuration

```nix
{
  nixpkgs.config.licenses."package-name" = {
    license = "commercial";
    
    # Option 1: Token file path
    tokenFile = ./secrets/license.token;
    
    # Option 2: Inline token
    token = ''
      NixLicense/1
      ...
    '';
  };
}
```

### Vendor CLI commands

```bash
# Generate keypair
nix-license keygen --vendor <domain> --output <dir>

# Issue token
nix-license issue \
    --signing-key <private-key> \
    --licensee <name> \
    --package <name> \
    --commercial true|false \
    --educational true|false \
    --government true|false \
    --military true|false \
    --redistribution true|false \
    --saas true|false \
    --seats <n>|unlimited \
    --machines <n>|unlimited \
    --expires <date> \
    --output <file>
```

### Attenuation rules

| Master value | Can attenuate to |
|--------------|------------------|
| `true` | `true` or `false` |
| `false` | `false` only |
| `seats = 500` | Any value ≤ 500 |
| `expires = 2025-12-31` | Any earlier date |
| (not set) | Can add new restrictions |

### Package definition

```nix
{ nixLicenseLib, commercialLicense ? null }:

let
  vendorPublicKeys = [ "ed25519:..." ];
  
  validated = nixLicenseLib.validateToken {
    token = commercialLicense;
    publicKeys = vendorPublicKeys;
    requiredClaims = { package = "..."; };
  };
in
  # Use validated.licensee, validated.expiresAt, etc.
```
