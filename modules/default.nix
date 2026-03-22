# nix-license standalone NixOS module
#
# Provides:
#   nixpkgs.config.allowClosedSource
#   nixpkgs.config.usage.*
#   nixpkgs.config.contentPolicy.*
#   nixpkgs.config.licenses.*
#   nixpkgs.config.licenseEnforcement

{ config, lib, oarsSpec, ... }:

let
  licenseTypes = import ../lib/types.nix { inherit lib oarsSpec; };

  cfg = config.nix-license;

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

    # Axis 1: Source availability
    allowClosedSource = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Accept closed-source packages";
    };

    # Axis 2: Usage context
    usage = {
      type = lib.mkOption {
        type = licenseTypes.usageType;
        default = "personal";
        description = "Primary usage context";
      };

      redistribution = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Distributing builds to others outside your organization";
      };

      saas = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Running software to provide services to third parties";
      };

      internal = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Usage limited to within your organization";
      };

      military = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Military, defense, or weapons-related use";
      };

      research = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Academic or scientific research use";
      };

      nonprofit = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Use by a registered nonprofit organization";
      };
    };

    # Axis 3: Content policy (system-wide default)
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

      warnExpiringSoon = lib.mkOption {
        type = lib.types.int;
        default = 30;
        description = "Warn when a token expires within this many days";
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
    # Wire nix-license settings into nixpkgs.config
    # This translates our typed options into the nixpkgs format
    nixpkgs.config = {
      allowUnfree = cfg.allowClosedSource;
    };
  };
}
