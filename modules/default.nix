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

    # Axis 2: Usage declaration
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
    nixpkgs.config = {
      allowUnfree = cfg.allowClosedSource;
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
    ];
  };
}
