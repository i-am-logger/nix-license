# nix-license mynixos integration module
#
# Extends the my.* namespace with:
#   my.license.enable
#   my.license.usage.*
#   my.license.contentPolicy.*
#   my.license.licenses.*
#   my.license.enforcement
#   my.users.<name>.contentPolicy.*

{ config, lib, oarsSpec, ... }:

let
  licenseTypes = import ../lib/types.nix { inherit lib oarsSpec; };

  cfg = config.my.license;

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

  # Per-user content policy submodule
  contentPolicySubmodule = lib.types.submodule {
    options = {
      preset = lib.mkOption {
        type = lib.types.nullOr licenseTypes.contentPolicyPresetType;
        default = null;
        description = ''
          Content policy preset. When set, provides defaults for all
          OARS categories. Individual categories can still be overridden.
        '';
      };

      allowUnrated = lib.mkOption {
        type = lib.types.bool;
        default = cfg.contentPolicy.allowUnrated;
        description = "Allow packages without content ratings";
      };
    } // mkOarsCategoryOptions;
  };
in
{
  # System-level license options under my.license.*
  options.my.license = {
    enable = lib.mkEnableOption "nix-license compliance";

    usage = {
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

    contentPolicy = {
      preset = lib.mkOption {
        type = lib.types.nullOr licenseTypes.contentPolicyPresetType;
        default = null;
        description = "System-wide content policy preset (default for all users)";
      };

      allowUnrated = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Allow packages without content ratings";
      };
    } // mkOarsCategoryOptions;

    licenses = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          license = lib.mkOption {
            type = lib.types.str;
            description = "License type override";
          };

          licenseId = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "License ID for audit";
          };

          expiresAt = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "License expiry date (ISO 8601)";
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
      description = "Per-package license overrides";
    };

    enforcement = lib.mkOption {
      type = licenseTypes.enforcementType;
      default = "warn";
      description = "License enforcement level";
    };

    vendorKeys = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = { };
      description = "Vendor public keys for token verification";
    };

    tokenVerification = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable cryptographic token verification";
      };

      requireTokens = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Packages that require a valid cryptographic token";
      };

      warnExpiringSoon = lib.mkOption {
        type = lib.types.int;
        default = 30;
        description = "Warn when a token expires within this many days";
      };
    };
  };

  # Per-user options under my.users.<name>
  options.my.users = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule (_: {
      # Per-user content policy
      options.contentPolicy = lib.mkOption {
        type = lib.types.either lib.types.str contentPolicySubmodule;
        default =
          if cfg.contentPolicy.preset != null then
            cfg.contentPolicy.preset
          else
            "unrestricted";
        description = ''
          Content policy for this user. Can be a preset string
          ("child", "teen", "unrestricted") or an attrset with
          per-category overrides.
        '';
      };

      # Per-user license tokens (attenuated from system tokens)
      options.licenseTokens = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            tokenFile = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              description = "Path to this user's attenuated license token file";
            };

            token = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Inline attenuated license token for this user";
            };
          };
        });
        default = { };
        description = ''
          Per-user license tokens. These are typically attenuated from
          system-level tokens, granting the user a subset of the
          system's license entitlements.
        '';
      };
    }));
  };

  # Wire my.license.* into the standalone nix-license module
  config = lib.mkIf cfg.enable {
    nix-license = {
      enable = true;
      inherit (cfg) enforcement vendorKeys;
      inherit (cfg) usage;
      inherit (cfg) contentPolicy licenses tokenVerification;
    };
  };
}

