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
  sharedOpts = import ../lib/options.nix { inherit lib licenseTypes; };

  isEnforce = cfg.enforcement == "enforce";

  # Embedded vendor public keys (shipped with nix-license)
  # Supports .asc (GPG) and .pem (openssl) key formats
  embeddedVendorKeysDir = ../keys/vendors;
  # Embedded vendor keys take priority — they are the source of trust.
  # User vendorKeys only for vendors not yet integrated into nix-license.
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
    # source-available is handled separately via SALT categories in checkPackageLicense
    assurances = lib.mapAttrs
      (n: a:
        if n == "source-available" then false
        else a.required && !builtins.elem pname a.exceptions)
      cfg.assurances;
  };

  # Check if a package's license conflicts with usage + license requirements
  # In enforce mode: returns false to block non-compliant packages
  # In warn mode: traces warnings and returns true (allows all packages)
  checkPackageLicense = pkg:
    let
      pname = pkg.pname or pkg.name or "unknown";
      rawLicenses = lib.toList (pkg.meta.license or [ ]);

      # Packages without a license: block for commercial, warn for non-commercial
      hasLicense = rawLicenses != [ ];
      missingLicenseBlocks = !hasLicense && cfg.usage.commercial-use;
      missingLicenseWarns = !hasLicense && !cfg.usage.commercial-use;

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
      licenseConflict = !(builtins.all (r: r.allowed) results) || missingLicenseBlocks || sourceConflict;

      conflicts = builtins.concatMap (r: r.conflicts) results;
      conflictMsg =
        if sourceConflict then "closed source (source-available assurance required)"
        else if missingLicenseBlocks then "no license declared (commercial use requires explicit license)"
        else if missingLicenseWarns then "no license declared"
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
      else if missingLicenseWarns then
        builtins.trace "nix-license: WARNING: ${pname} has no license declared" true
      else true
    else if isEnforce then
      builtins.trace "nix-license: BLOCKED: ${pname}: ${conflictMsg}" false
    else builtins.trace "nix-license: WARNING: ${pname}: ${conflictMsg}" true;

in
{
  options.nix-license = {
    enable = lib.mkEnableOption "nix-license compliance module";

    name = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "System name (e.g., 'yoga', 'prod-web-01')";
    };

    description = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "System description (e.g., 'Primary development workstation')";
    };

    usage = sharedOpts.usageOptions;
    commitments = sharedOpts.commitmentOptions;
    assurances = sharedOpts.assuranceOptions;
    contentPolicy = sharedOpts.contentPolicyOptions;

    licenses = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule { options = sharedOpts.licenseSubmoduleOptions; });
      default = { };
      description = "Per-package license overrides and commercial license declarations";
    };

    vendorKeys = sharedOpts.vendorKeysOption;
    enforcement = sharedOpts.enforcementOption;

    report = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      description = "License compliance report bundle (JSON + HTML). Build with: nix build .#nixosConfigurations.<host>.config.nix-license.report";
    };
  };

  config = lib.mkIf cfg.enable {
    # Mark all licenses as unfree so allowUnfreePredicate fires for every package.
    # Without this, nixpkgs only checks packages where meta.license.free = false,
    # meaning copyleft licenses (GPL, AGPL) would bypass commitment checks.
    nixpkgs.overlays = [
      (_: prev: {
        lib = prev.lib // {
          licenses = builtins.mapAttrs
            (_: lic: if builtins.isAttrs lic then lic // { free = false; } else lic)
            prev.lib.licenses;
        };
      })
    ];

    nixpkgs.config = {
      # nix-license handles all compliance — allowUnfreePredicate fires for
      # every package because the overlay marks all licenses as unfree.
      allowUnfreePredicate = checkPackageLicense;
    };

    # Content policy + installed license files
    environment.etc =
      {
        "nix-license/content-policy/system.json" = {
          source = pkgs.writeText "nix-license-content-policy-system.json"
            (builtins.toJSON (contentRating.resolveContentPolicy
              (if cfg.contentPolicy.preset != null then cfg.contentPolicy.preset else "unrestricted")));
          mode = "0644";
          user = "root";
          group = "root";
        };
      }
      // lib.mapAttrs'
        (pname: licCfg:
          lib.nameValuePair "nix-license/licenses/${pname}.token" {
            source = licCfg.licenseFile;
            mode = "0400";
            user = "root";
            group = "root";
          })
        (lib.filterAttrs (_: licCfg: licCfg.install) cfg.licenses);

    # License compliance report (commercial feature — requires a nix-license commercial license)
    nix-license.report =
      let
        hasNixLicense = cfg.licenses ? "nix-license";
        reportLib = import ../lib/report.nix {
          inherit lib pkgs licenseCheck nixpkgsMap mkUsageContext cfg;
          title =
            if cfg.name != "" && cfg.description != "" then "${cfg.name} — ${cfg.description}"
            else if cfg.name != "" then cfg.name
            else if cfg.description != "" then cfg.description
            else "License Compliance Report";
        };
      in
      assert hasNixLicense || throw ''
        nix-license: report generation requires a nix-license commercial license.
        Add: nix-license.licenses."nix-license".licenseFile = ./path/to/license;
        Visit https://github.com/i-am-logger/nix-license for licensing.
      '';
      reportLib.mkReportBundle (config.environment.systemPackages or [ ]);

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
            hasNixLicense = cfg.licenses ? "nix-license";
          in
            !(cfg.usage.commercial-use && cfg.enforcement == "enforce" && !hasNixLicense);
        message = ''
          nix-license: commercial use requires a nix-license commercial license in enforce mode.
          Add: nix-license.licenses."nix-license".licenseFile = ./path/to/license;
          Visit https://github.com/i-am-logger/nix-license for licensing.
        '';
      }
    ];
  };
}
