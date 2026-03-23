# Shared option definitions for default.nix and mynixos.nix
# Single source of truth — prevents divergence between nix-license.* and my.license.*

{ lib, licenseTypes }:

let
  mkOarsCategoryOptions = builtins.listToAttrs (map
    (cat: {
      name = cat;
      value = lib.mkOption {
        type = licenseTypes.policySeverityType;
        default = "intense";
        description = "Maximum allowed severity for ${cat}";
      };
    })
    licenseTypes.oarsCategories);

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
  usageOptions = {
    type = lib.mkOption {
      type = lib.types.enum [ "personal" "commercial" "educational" "research" "government" "nonprofit" ];
      description = "What type of organization or individual are you?";
    };

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

  commitmentOptions = {
    include-copyright = mkCommitment "Can you include copyright notices when distributing?";
    disclose-source = mkCommitment "Can you disclose source code when required?";
    same-license = mkCommitment "Can you distribute under the same license (copyleft)?";
    same-license--file = mkCommitment "Can you apply the same license per-file (weak copyleft)?";
    same-license--library = mkCommitment "Can you apply the same license for linked libraries (LGPL)?";
    document-changes = mkCommitment "Can you document changes to modified source code?";
    network-use-disclose = mkCommitment "Can you disclose source for network service use (AGPL)?";
  };

  assuranceOptions = {
    source-available = mkAssurance "Require source code to be available? Blocks closed-source packages.";
    patent-grant = mkAssurance "Require licenses to grant patent rights?";
    liability-coverage = mkAssurance "Require licenses to not disclaim liability?";
    warranty = mkAssurance "Require licenses to not disclaim warranty?";
  };

  contentPolicyOptions = {
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

  licenseSubmoduleOptions = {
    licenseFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to signed license token file (GPG or openssl)";
    };

    install = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install license file to /etc/nix-license/licenses/ for runtime use";
    };
  };

  vendorKeysOption = lib.mkOption {
    type = lib.types.attrsOf lib.types.path;
    default = { };
    description = ''
      Vendor public keys for packages not yet integrated into nix-license.
      Keyed by package name, value is path to the vendor's public key.
    '';
  };

  enforcementOption = lib.mkOption {
    type = licenseTypes.enforcementType;
    default = "warn";
    description = "License enforcement level: 'warn' logs warnings, 'enforce' blocks builds";
  };
}
