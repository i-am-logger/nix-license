# nix-license mynixos integration module
#
# Extends the my.* namespace with:
#   my.license.enable
#   my.license.usage.*
#   my.license.contentPolicy.*
#   my.license.licenses.*
#   my.license.enforcement
#   my.users.<name>.contentPolicy.*

{ config, lib, pkgs, oarsSpec, ... }:

let
  licenseTypes = import ../lib/types.nix { inherit lib oarsSpec; };
  contentRating = import ../lib/content-rating.nix { inherit lib oarsSpec; };
  sharedOpts = import ../lib/options.nix { inherit lib licenseTypes; };

  cfg = config.my.license;

  # Per-user content policy submodule (inherits system defaults)
  contentPolicySubmodule = lib.types.submodule {
    options = {
      preset = lib.mkOption {
        type = lib.types.nullOr licenseTypes.contentPolicyPresetType;
        default = null;
        description = "Content policy preset for this user.";
      };

      allowUnrated = lib.mkOption {
        type = lib.types.bool;
        default = cfg.contentPolicy.allowUnrated;
        description = "Allow packages without content ratings";
      };
    } // builtins.listToAttrs (map
      (cat: {
        name = cat;
        value = lib.mkOption {
          type = licenseTypes.policySeverityType;
          default = "intense";
          description = "Maximum allowed severity for ${cat}";
        };
      })
      licenseTypes.oarsCategories);
  };
in
{
  # System-level license options under my.license.*
  options.my.license = {
    enable = lib.mkEnableOption "nix-license compliance";

    usage = sharedOpts.usageOptions;
    commitments = sharedOpts.commitmentOptions;
    assurances = sharedOpts.assuranceOptions;
    contentPolicy = sharedOpts.contentPolicyOptions;

    licenses = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule { options = sharedOpts.licenseSubmoduleOptions; });
      default = { };
      description = "Per-package license overrides";
    };

    vendorKeys = sharedOpts.vendorKeysOption;
    enforcement = sharedOpts.enforcementOption;
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
    }));
  };

  # Wire my.license.* into the standalone nix-license module
  config = lib.mkIf cfg.enable {
    nix-license = {
      enable = true;
      inherit (cfg) enforcement vendorKeys;
      inherit (cfg) usage commitments assurances;
      inherit (cfg) contentPolicy licenses;
    };

    # Per-user content policy files — immutable, user-owned
    environment.etc = lib.mapAttrs'
      (username: userCfg:
        lib.nameValuePair "nix-license/content-policy/${username}.json" {
          source = pkgs.writeText "nix-license-content-policy-${username}.json"
            (builtins.toJSON (contentRating.resolveContentPolicy userCfg.contentPolicy));
          mode = "0400";
          user = username;
          group = "root";
        })
      config.my.users;
  };
}
