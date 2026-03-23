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

    commitments =
      let
        mkC = description: {
          fulfilled = lib.mkOption { type = lib.types.bool; default = true; inherit description; };
          exceptions = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ ]; description = "Package names exempt from this commitment."; };
        };
      in
      {
        include-copyright = mkC "Can you include copyright notices when distributing?";
        disclose-source = mkC "Can you disclose source code when required?";
        same-license = mkC "Can you distribute under the same license (copyleft)?";
        same-license--file = mkC "Can you apply the same license per-file (weak copyleft)?";
        same-license--library = mkC "Can you apply the same license for linked libraries (LGPL)?";
        document-changes = mkC "Can you document changes to modified source code?";
        network-use-disclose = mkC "Can you disclose source for network service use (AGPL)?";
      };

    assurances = {
      source-available = {
        required = lib.mkOption { type = lib.types.bool; default = false; description = "Require source code to be available?"; };
        exceptions = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ ]; description = "Package names exempt from this assurance."; };
      };
      patent-grant = {
        required = lib.mkOption { type = lib.types.bool; default = false; description = "Require licenses to grant patent rights?"; };
        exceptions = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ ]; description = "Package names exempt from this assurance."; };
      };
      liability-coverage = {
        required = lib.mkOption { type = lib.types.bool; default = false; description = "Require licenses to not disclaim liability?"; };
        exceptions = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ ]; description = "Package names exempt from this assurance."; };
      };
      warranty = {
        required = lib.mkOption { type = lib.types.bool; default = false; description = "Require licenses to not disclaim warranty?"; };
        exceptions = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ ]; description = "Package names exempt from this assurance."; };
      };
    };

    licenses = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
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
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = "Vendor public keys for packages not yet in nix-license (keyed by package name)";
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
            licenseFile = lib.mkOption {
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

