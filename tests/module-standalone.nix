{ lib, oarsSpec, saltLicenses ? { }, saltSpdx ? { }, pkgs ? { writeText = name: _: "/nix/store/fake-${name}"; } }:

let
  evalModule = extraConfig:
    (lib.evalModules {
      modules = [
        ../modules/default.nix
        {
          options = {
            nixpkgs.config = lib.mkOption { type = lib.types.attrs; default = { }; };
            assertions = lib.mkOption { type = lib.types.listOf lib.types.attrs; default = [ ]; };
            environment.etc = lib.mkOption { type = lib.types.attrs; default = { }; };
          };
        }
        { _module.args = { inherit oarsSpec saltLicenses saltSpdx pkgs; }; }
        extraConfig
      ];
    }).config;

  defaultUsage = {
    nix-license.usage = {
      type = "personal";
      commercial-use = false;
      distribution = false;
      modifications = false;
      saas = false;
    };
  };

  assertEq = name: actual: expected:
    if actual == expected then true
    else throw "FAIL: ${name}: expected ${builtins.toJSON expected}, got ${builtins.toJSON actual}";

  assertTrue = name: value:
    if value then true
    else throw "FAIL: ${name}";

  assertFalse = name: value:
    if !value then true
    else throw "FAIL: ${name}";

in
{
  defaultDisabled =
    let cfg = evalModule defaultUsage;
    in assertFalse "disabled by default" cfg.nix-license.enable;

  enableSetsPredicate =
    let cfg = evalModule (defaultUsage // { nix-license.enable = true; });
    in assertTrue "enable sets allowUnfreePredicate" (cfg.nixpkgs.config ? allowUnfreePredicate);

  usageType =
    let
      cfg = evalModule {
        nix-license.usage = { type = "educational"; commercial-use = false; distribution = true; modifications = true; saas = false; };
      };
    in
    assertEq "type is educational" cfg.nix-license.usage.type "educational";

  usageCommercial =
    let
      cfg = evalModule {
        nix-license.usage = { type = "commercial"; commercial-use = true; distribution = false; modifications = true; saas = false; };
      };
    in
    assertTrue "commercial-use set" cfg.nix-license.usage.commercial-use;

  scenarioCompany =
    let
      cfg = evalModule {
        nix-license = {
          enable = true;
          usage = { type = "commercial"; commercial-use = true; distribution = false; modifications = true; saas = false; };
          enforcement = "enforce";
        };
      };
    in
    assertTrue "company scenario"
      (cfg.nix-license.usage.type == "commercial"
        && cfg.nix-license.usage.commercial-use
        && cfg.nix-license.enforcement == "enforce"
        && cfg.nixpkgs.config ? allowUnfreePredicate);

  scenarioSaas =
    let
      cfg = evalModule {
        nix-license = {
          enable = true;
          usage = { type = "commercial"; commercial-use = true; distribution = true; modifications = true; saas = true; };
        };
      };
    in
    assertTrue "saas scenario" (cfg.nix-license.usage.saas && cfg.nix-license.usage.commercial-use);

  scenarioEducational =
    let
      cfg = evalModule {
        nix-license = {
          enable = true;
          usage = { type = "educational"; commercial-use = false; distribution = true; modifications = true; saas = false; };
        };
      };
    in
    assertEq "educational type" cfg.nix-license.usage.type "educational";

  assertionPersonalCommercial =
    let
      cfg = evalModule {
        nix-license = {
          enable = true;
          usage = { type = "personal"; commercial-use = true; distribution = false; modifications = false; saas = false; };
        };
      };
    in
    assertTrue "assertion catches personal+commercial"
      (builtins.any (a: !a.assertion) cfg.assertions);

  assertionSaasNotCommercial =
    let
      cfg = evalModule {
        nix-license = {
          enable = true;
          usage = { type = "commercial"; commercial-use = false; distribution = false; modifications = false; saas = true; };
        };
      };
    in
    assertTrue "assertion catches saas without commercial-use"
      (builtins.any (a: !a.assertion) cfg.assertions);

  # ── Commitments defaults ──────────────────────────────────────

  commitmentsDefaultFulfilled =
    let
      cfg = evalModule defaultUsage;
    in
    assertTrue "commitments default to fulfilled"
      (cfg.nix-license.commitments.same-license.fulfilled
        && cfg.nix-license.commitments.disclose-source.fulfilled
        && cfg.nix-license.commitments.include-copyright.fulfilled);

  commitmentsCanDisable =
    let
      cfg = evalModule (defaultUsage // {
        nix-license.commitments.same-license.fulfilled = false;
      });
    in
    assertFalse "can disable same-license commitment"
      cfg.nix-license.commitments.same-license.fulfilled;

  commitmentsExceptions =
    let
      cfg = evalModule (defaultUsage // {
        nix-license.commitments.same-license = {
          fulfilled = false;
          exceptions = [ "libfoo" "libbar" ];
        };
      });
    in
    assertTrue "commitments support exceptions"
      (!cfg.nix-license.commitments.same-license.fulfilled
        && builtins.elem "libfoo" cfg.nix-license.commitments.same-license.exceptions);

  # ── Assurances defaults ───────────────────────────────────────

  assurancesDefaultFalse =
    let
      cfg = evalModule defaultUsage;
    in
    assertTrue "assurances default to not required"
      (!cfg.nix-license.assurances.patent-grant.required
        && !cfg.nix-license.assurances.liability-coverage.required
        && !cfg.nix-license.assurances.warranty.required
        && !cfg.nix-license.assurances.source-available.required);

  # ── Commercial gate ────────────────────────────────────────────

  commercialEnforceRequiresToken =
    let
      cfg = evalModule {
        nix-license = {
          enable = true;
          usage = { type = "commercial"; commercial-use = true; distribution = false; modifications = true; saas = false; };
          enforcement = "enforce";
        };
      };
    in
    assertTrue "commercial enforce without token triggers assertion"
      (builtins.any (a: !a.assertion && builtins.match ".*commercial use requires.*" a.message != null) cfg.assertions);

  commercialEnforceWithTokenPasses =
    let
      cfg = evalModule {
        nix-license = {
          enable = true;
          usage = { type = "commercial"; commercial-use = true; distribution = false; modifications = true; saas = false; };
          enforcement = "enforce";
          licenses."nix-license" = {
            licenseFile = "/fake/nix-license.token";
          };
        };
      };
    in
    assertTrue "commercial enforce with token passes assertion"
      (builtins.all (a: a.assertion || builtins.match ".*commercial use requires.*" a.message == null) cfg.assertions);

  commercialWarnNoTokenOk =
    let
      cfg = evalModule {
        nix-license = {
          enable = true;
          usage = { type = "commercial"; commercial-use = true; distribution = false; modifications = true; saas = false; };
          enforcement = "warn";
        };
      };
    in
    assertTrue "commercial warn mode doesn't require token"
      (builtins.all (a: a.assertion || builtins.match ".*commercial use requires.*" a.message == null) cfg.assertions);

  personalEnforceNoTokenOk =
    let
      cfg = evalModule {
        nix-license = {
          enable = true;
          usage = { type = "personal"; commercial-use = false; distribution = false; modifications = true; saas = false; };
          enforcement = "enforce";
        };
      };
    in
    assertTrue "personal enforce doesn't require token"
      (builtins.all (a: a.assertion || builtins.match ".*commercial use requires.*" a.message == null) cfg.assertions);

  # ── Proprietary company scenario ──────────────────────────────

  scenarioProprietaryCompany =
    let
      cfg = evalModule {
        nix-license = {
          enable = true;
          usage = { type = "commercial"; commercial-use = true; distribution = true; modifications = true; saas = false; };
          commitments.same-license.fulfilled = false;
          commitments.disclose-source.fulfilled = false;
          enforcement = "enforce";
          licenses."nix-license".licenseFile = "/fake/nix-license.token";
        };
      };
    in
    assertTrue "proprietary company scenario"
      (!cfg.nix-license.commitments.same-license.fulfilled
        && !cfg.nix-license.commitments.disclose-source.fulfilled
        && cfg.nix-license.commitments.include-copyright.fulfilled);

  # ── License overrides ──────────────────────────────────────────

  vendorLicenseOverride =
    let
      cfg = evalModule (defaultUsage // {
        nix-license.licenses."vendor-package" = {
          licenseFile = "/fake/vendor.token";
        };
      });
    in
    assertTrue "can set vendor license with licenseFile"
      (cfg.nix-license.licenses."vendor-package".licenseFile == "/fake/vendor.token");

  nixLicenseTokenAsOverride =
    let
      cfg = evalModule {
        nix-license = {
          enable = true;
          usage = { type = "commercial"; commercial-use = true; distribution = false; modifications = true; saas = false; };
          enforcement = "enforce";
          licenses."nix-license" = {
            licenseFile = "/fake/nix-license.token";
          };
        };
      };
    in
    assertTrue "nix-license token via licenses override"
      (cfg.nix-license.licenses."nix-license".licenseFile == "/fake/nix-license.token");

  # ── Vendor keys ────────────────────────────────────────────────

  vendorKeysDefault =
    let
      cfg = evalModule defaultUsage;
    in
    assertTrue "vendorKeys default empty"
      (cfg.nix-license.vendorKeys == { });

  vendorKeysCanSet =
    let
      cfg = evalModule (defaultUsage // {
        nix-license.vendorKeys."some-tool" = "/fake/some-vendor.pem";
      });
    in
    assertTrue "can set vendor key for package"
      (cfg.nix-license.vendorKeys."some-tool" == "/fake/some-vendor.pem");

  embeddedNixLicenseKey =
    assertTrue "nix-license vendor key exists (symlink to yubikey1)"
      (builtins.pathExists ../keys/vendors/nix-license.asc
        && builtins.pathExists ../keys/yubikey1.asc);

  # ── Content policy files ──────────────────────────────────────

  contentPolicyFileCreated =
    let
      cfg = evalModule (defaultUsage // { nix-license.enable = true; });
    in
    assertTrue "system content policy file created"
      (cfg.environment.etc ? "nix-license/content-policy/system.json");

  contentPolicySystemPermissions =
    let
      cfg = evalModule (defaultUsage // { nix-license.enable = true; });
      etc = cfg.environment.etc."nix-license/content-policy/system.json";
    in
    assertTrue "system policy: root:root, 0644"
      (etc.mode == "0644" && etc.user == "root" && etc.group == "root");

  # ── Assurance submodule ───────────────────────────────────────

  assuranceExceptionsDefault =
    let
      cfg = evalModule defaultUsage;
    in
    assertTrue "assurance exceptions default empty"
      (cfg.nix-license.assurances.source-available.exceptions == [ ]
        && cfg.nix-license.assurances.patent-grant.exceptions == [ ]);

  assuranceCanSetExceptions =
    let
      cfg = evalModule (defaultUsage // {
        nix-license.assurances.source-available = {
          required = true;
          exceptions = [ "nvidia-x11" "firmware-linux-nonfree" ];
        };
      });
    in
    assertTrue "can set source-available with exceptions"
      (cfg.nix-license.assurances.source-available.required
        && builtins.elem "nvidia-x11" cfg.nix-license.assurances.source-available.exceptions
        && builtins.length cfg.nix-license.assurances.source-available.exceptions == 2);

  assurancePatentWithExceptions =
    let
      cfg = evalModule (defaultUsage // {
        nix-license.assurances.patent-grant = {
          required = true;
          exceptions = [ "some-legacy-lib" ];
        };
      });
    in
    assertTrue "can set patent-grant with exceptions"
      (cfg.nix-license.assurances.patent-grant.required
        && builtins.elem "some-legacy-lib" cfg.nix-license.assurances.patent-grant.exceptions);
}
