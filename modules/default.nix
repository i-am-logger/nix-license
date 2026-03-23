# nix-license standalone NixOS module
#
# Provides:
#   nix-license.usage.*
#   nix-license.commitments.*
#   nix-license.assurances.*
#   nix-license.contentPolicy.*
#   nix-license.licenses.*
#   nix-license.enforcement

{ config, lib, pkgs, oarsSpec, saltLicenses, saltSpdx, ... }:

let
  licenseTypes = import ../lib/types.nix { inherit lib oarsSpec; };
  contentRating = import ../lib/content-rating.nix { inherit lib oarsSpec; };
  licenseCheck = import ../lib/license-check.nix { };
  nixpkgsMap = import ../lib/nixpkgs-map.nix { inherit saltLicenses saltSpdx; };

  isEnforce = cfg.enforcement == "enforce";

  cfg = config.nix-license;

  # Convert a nixpkgs license to SALT format for evaluation
  # Fails if license is not found in SALT
  toSaltLicense = nixpkgsLicense:
    let
      saltLic = nixpkgsMap.lookup nixpkgsLicense;
      name = nixpkgsLicense.shortName or nixpkgsLicense.spdxId or "unknown";
    in
    if saltLic != null then saltLic
    else throw "nix-license: license '${name}' not found in SALT. Add it to SALT or lib/nixpkgs-map.nix.";

  # Build the full usage context including policy
  usageContext = cfg.usage // {
    inherit (cfg) commitments assurances;
  };

  # Check if a package's license conflicts with usage + token requirements
  # In enforce mode: returns false to block non-compliant packages
  # In warn mode: traces warnings and returns true (allows all packages)
  checkPackageLicense = pkg:
    let
      pname = pkg.pname or pkg.name or "unknown";
      rawLicenses = lib.toList (pkg.meta.license or [ ]);

      # Packages without a license: block for commercial, warn for non-commercial
      hasLicense = rawLicenses != [ ];
      noLicenseConflict = !hasLicense && cfg.usage.commercial-use;
      noLicenseWarning = !hasLicense && !cfg.usage.commercial-use;

      results = map (nixLic: licenseCheck.evaluateLicenseUsage usageContext (toSaltLicense nixLic)) rawLicenses;
      licenseAllowed = builtins.all (r: r.allowed) results && !noLicenseConflict;

      conflicts = builtins.concatMap (r: r.conflicts) results;
      conflictMsg =
        if noLicenseConflict then "no license declared (commercial use requires explicit license)"
        else if noLicenseWarning then "no license declared"
        else lib.concatMapStringsSep ", " (c: c.reason) conflicts;

      # Token requirement check
      requiresToken = cfg.tokenVerification.enable
        && builtins.elem pname cfg.tokenVerification.requireTokens;
      hasToken = cfg.licenses ? ${pname}
        && (cfg.licenses.${pname}.token != null || cfg.licenses.${pname}.tokenFile != null);
      tokenSatisfied = !requiresToken || hasToken;

      compliant = licenseAllowed && tokenSatisfied;
    in
    if compliant then
    # Even compliant packages get a warning if they have no license
      if noLicenseWarning then
        builtins.trace "nix-license: WARNING: ${pname} has no license declared" true
      else true
    else if isEnforce then false
    else builtins.trace "nix-license: WARNING: ${pname}: ${conflictMsg}" true;

  severityOption = cat: lib.mkOption {
    type = licenseTypes.policySeverityType;
    default = "intense";
    description = "Maximum allowed severity for ${cat}";
  };

  mkOarsCategoryOptions = builtins.listToAttrs (map
    (cat: {
      name = cat;
      value = severityOption cat;
    })
    licenseTypes.oarsCategories);
in
{
  options.nix-license = {
    enable = lib.mkEnableOption "nix-license compliance module";

    # Usage declaration
    # All fields are required — you must explicitly declare your usage.
    usage = {
      # Who you are — checked against SALT allowed-use lists
      type = lib.mkOption {
        type = lib.types.enum [ "personal" "commercial" "educational" "research" "government" "nonprofit" ];
        description = "What type of organization or individual are you?";
      };

      # What you do — each matches a SALT restriction key
      commercial-use = lib.mkOption {
        type = lib.types.bool;
        description = "Are you using software for commercial purposes?";
      };

      distribution = lib.mkOption {
        type = lib.types.bool;
        description = "Are you distributing software to others?";
      };

      modifications = lib.mkOption {
        type = lib.types.bool;
        description = "Are you modifying the software source code?";
      };

      saas = lib.mkOption {
        type = lib.types.bool;
        description = "Are you providing the software as a hosted or managed service?";
      };
    };

    # Commitments — which license obligations you can fulfill
    # If an obligation triggers and you set its commitment to false, the package is blocked.
    commitments = {
      include-copyright = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Can you include copyright notices when distributing?";
      };

      disclose-source = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Can you disclose source code when required?";
      };

      same-license = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Can you distribute under the same license (copyleft)?";
      };

      same-license--file = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Can you apply the same license per-file (weak copyleft)?";
      };

      same-license--library = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Can you apply the same license for linked libraries (LGPL)?";
      };

      document-changes = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Can you document changes to modified source code?";
      };

      network-use-disclose = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Can you disclose source for network service use (AGPL)?";
      };
    };

    # Assurances — what guarantees you require from licenses
    # If a license disclaims something you require, the package is blocked.
    assurances = {
      patent-grant = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Require licenses to grant patent rights?";
      };

      liability-coverage = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Require licenses to not disclaim liability?";
      };

      warranty = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Require licenses to not disclaim warranty?";
      };
    };

    # Content policy (system-wide default)
    contentPolicy = {
      preset = lib.mkOption {
        type = lib.types.nullOr licenseTypes.contentPolicyPresetType;
        default = null;
        description = ''
          Content policy preset. When set, provides defaults for all
          OARS categories. Individual categories can still be overridden.
          If null, defaults to unrestricted.
        '';
      };

      allowUnrated = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Allow packages without content ratings";
      };
    } // mkOarsCategoryOptions;

    # Per-package license overrides
    licenses = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          license = lib.mkOption {
            type = lib.types.str;
            description = "License type override (e.g., 'commercial')";
          };

          licenseId = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "License ID for documentation/audit";
          };

          expiresAt = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "License expiry date (ISO 8601), enables expiry warnings";
          };

          tokenFile = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = "Path to cryptographic license token file";
          };

          token = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Inline cryptographic license token";
          };
        };
      });
      default = { };
      description = "Per-package license overrides and commercial license declarations";
    };

    # Vendor public keys for token verification
    vendorKeys = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = { };
      description = ''
        Vendor public keys for verifying license tokens.
        Keys are keyed by vendor domain, values are lists of
        Ed25519 public keys (for key rotation support).
        Example: { "vendor.example.com" = [ "ed25519:..." ]; }
      '';
    };

    # Token verification settings
    tokenVerification = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable cryptographic token verification at build time";
      };

      requireTokens = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          List of package names that require a valid cryptographic token.
          Packages in this list will fail to build without a verified token.
        '';
      };
    };

    # nix-license commercial token
    # Required when usage.commercial-use = true and enforcement = "enforce"
    license = {
      token = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          Inline nix-license commercial token (GPG-signed JSON).
          Required for commercial use in enforce mode.
        '';
      };

      tokenFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          Path to nix-license commercial token file.
          Required for commercial use in enforce mode.
        '';
      };
    };

    # Enforcement level
    enforcement = lib.mkOption {
      type = licenseTypes.enforcementType;
      default = "warn";
      description = "License enforcement level: 'warn' logs warnings, 'enforce' blocks builds";
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.config = {
      # Always use the predicate so both warn and enforce modes work.
      # Warn mode: predicate traces warnings and returns true (allows all).
      # Enforce mode: predicate returns false for non-compliant packages.
      allowUnfreePredicate = checkPackageLicense;
    };

    # Content policy files — immutable, symlinked to Nix store
    environment.etc."nix-license/content-policy/system.json".source =
      pkgs.writeText "nix-license-content-policy-system.json"
        (builtins.toJSON (contentRating.resolveContentPolicy
          (if cfg.contentPolicy.preset != null then cfg.contentPolicy.preset else "unrestricted")));

    # Usage consistency assertions
    assertions = [
      {
        assertion = !(cfg.usage.type == "personal" && cfg.usage.commercial-use);
        message = "nix-license: type is 'personal' but commercial-use is true. Personal use is non-commercial.";
      }
      {
        assertion = !(cfg.usage.saas && !cfg.usage.commercial-use);
        message = "nix-license: saas is true but commercial-use is false. SaaS is commercial use.";
      }
      {
        assertion = !(cfg.usage.commercial-use && cfg.enforcement == "enforce"
          && cfg.license.token == null && cfg.license.tokenFile == null);
        message = ''
          nix-license: commercial use requires a valid nix-license token in enforce mode.
          Set nix-license.license.token or nix-license.license.tokenFile.
          Visit https://github.com/i-am-logger/nix-license for licensing.
        '';
      }
    ];
  };
}
