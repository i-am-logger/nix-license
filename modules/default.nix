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

  # Embedded vendor public keys (shipped with nix-license)
  # Supports .asc (GPG) and .pem (openssl) key formats
  embeddedVendorKeysDir = ../keys/vendors;
  getVendorKey = pname:
    let
      pemPath = embeddedVendorKeysDir + "/${pname}.pem";
      ascPath = embeddedVendorKeysDir + "/${pname}.asc";
    in
    if builtins.pathExists pemPath then { type = "pem"; path = pemPath; }
    else if builtins.pathExists ascPath then { type = "gpg"; path = ascPath; }
    else if cfg.vendorKeys ? ${pname} then { type = "pem"; path = cfg.vendorKeys.${pname}; }
    else null;

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
  # Commitments and assurances are resolved per-package (exceptions applied)
  mkUsageContext = pname: cfg.usage // {
    commitments = lib.mapAttrs
      (_: c:
        let isExcepted = builtins.elem pname c.exceptions;
        in if c.fulfilled then !isExcepted   # can fulfill, except these
        else isExcepted                       # can't fulfill, except these CAN
      )
      cfg.commitments;
    assurances = lib.mapAttrs
      (_: a: a.required && !builtins.elem pname a.exceptions)
      cfg.assurances;
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

      # Source availability check — uses SALT category, not nixpkgs free flag
      # (nixpkgs free=false includes CC-BY-NC which HAS source)
      closedCategories = [ "Commercial" "Proprietary Free" ];
      isClosed = builtins.any
        (nixLic:
          let salt = nixpkgsMap.lookup nixLic;
          in salt != null && builtins.elem (salt.category or "") closedCategories
        )
        rawLicenses;
      isExcepted = builtins.elem pname cfg.assurances.source-available.exceptions;
      sourceConflict = cfg.assurances.source-available.required && isClosed && !isExcepted;

      usageContext = mkUsageContext pname;
      results = map (nixLic: licenseCheck.evaluateLicenseUsage usageContext (toSaltLicense nixLic)) rawLicenses;
      licenseConflict = !(builtins.all (r: r.allowed) results) || noLicenseConflict || sourceConflict;

      conflicts = builtins.concatMap (r: r.conflicts) results;
      conflictMsg =
        if sourceConflict then "closed source (source-available assurance required)"
        else if noLicenseConflict then "no license declared (commercial use requires explicit license)"
        else if noLicenseWarning then "no license declared"
        else lib.concatMapStringsSep ", " (c: c.reason) conflicts;

      # License override: if a conflict exists but the user has a
      # license for this package, allow it (vendor key verified at build time)
      hasOverride = cfg.licenses ? ${pname};
      vendorKey = getVendorKey pname;
      hasVendorKey = vendorKey != null;
      overridden = licenseConflict && hasOverride;

      compliant = !licenseConflict || overridden;
    in
    if compliant then
      if hasOverride && !hasVendorKey then
      # License exists but no vendor key — can't verify signature
        if isEnforce then
          builtins.trace "nix-license: ERROR: ${pname}: no vendor key, cannot verify license" false
        else
          builtins.trace "nix-license: WARNING: ${pname}: unverified license (no vendor key)" true
      else if noLicenseWarning then
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
    # If an obligation triggers and you can't fulfill it, the package is blocked.
    # fulfilled=true (default): can fulfill. exceptions = packages you CAN'T fulfill for.
    # fulfilled=false: can't fulfill. exceptions = packages you CAN fulfill for.
    commitments =
      let
        mkCommitment = description: {
          fulfilled = lib.mkOption {
            type = lib.types.bool;
            default = true;
            inherit description;
          };
          exceptions = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Package names exempt from this commitment.";
          };
        };
      in
      {
        include-copyright = mkCommitment "Can you include copyright notices when distributing?";
        disclose-source = mkCommitment "Can you disclose source code when required?";
        same-license = mkCommitment "Can you distribute under the same license (copyleft)?";
        same-license--file = mkCommitment "Can you apply the same license per-file (weak copyleft)?";
        same-license--library = mkCommitment "Can you apply the same license for linked libraries (LGPL)?";
        document-changes = mkCommitment "Can you document changes to modified source code?";
        network-use-disclose = mkCommitment "Can you disclose source for network service use (AGPL)?";
      };

    # Assurances — what guarantees you require from licenses
    # If a license disclaims something you require, the package is blocked.
    # Each assurance has { required; exceptions; } — exceptions are package names.
    assurances =
      let
        mkAssurance = description: {
          required = lib.mkOption {
            type = lib.types.bool;
            default = false;
            inherit description;
          };
          exceptions = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Package names exempt from this assurance.";
          };
        };
      in
      {
        source-available = mkAssurance "Require source code to be available? Blocks closed-source packages.";
        patent-grant = mkAssurance "Require licenses to grant patent rights?";
        liability-coverage = mkAssurance "Require licenses to not disclaim liability?";
        warranty = mkAssurance "Require licenses to not disclaim warranty?";
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
          licenseFile = lib.mkOption {
            type = lib.types.path;
            description = "Path to signed license token file (GPG or openssl)";
          };
        };
      });
      default = { };
      description = "Per-package license overrides and commercial license declarations";
    };

    # Additional vendor public keys (for vendors not yet in keys/vendors/)
    # Keyed by package name, value is path to public key file (.pem or .asc)
    vendorKeys = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = ''
        Vendor public keys for packages not yet integrated into nix-license.
        Keyed by package name, value is path to the vendor's public key.
        Example: { "some-tool" = ./keys/some-vendor.pem; }
      '';
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

    # Content policy files — immutable, proper ownership
    environment.etc."nix-license/content-policy/system.json" = {
      source = pkgs.writeText "nix-license-content-policy-system.json"
        (builtins.toJSON (contentRating.resolveContentPolicy
          (if cfg.contentPolicy.preset != null then cfg.contentPolicy.preset else "unrestricted")));
      mode = "0644";
      user = "root";
      group = "root";
    };

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
        assertion =
          let
            hasNixLicenseToken = cfg.licenses ? "nix-license";
          in
            !(cfg.usage.commercial-use && cfg.enforcement == "enforce" && !hasNixLicenseToken);
        message = ''
          nix-license: commercial use requires a nix-license token in enforce mode.
          Add: nix-license.licenses."nix-license".licenseFile = ./path/to/token;
          Visit https://github.com/i-am-logger/nix-license for licensing.
        '';
      }
    ];
  };
}
