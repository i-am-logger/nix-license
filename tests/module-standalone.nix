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

  commitmentsDefaultTrue =
    let
      cfg = evalModule defaultUsage;
    in
    assertTrue "commitments default to true"
      (cfg.nix-license.commitments.same-license
        && cfg.nix-license.commitments.disclose-source
        && cfg.nix-license.commitments.include-copyright);

  commitmentsCanDisable =
    let
      cfg = evalModule (defaultUsage // {
        nix-license.commitments.same-license = false;
      });
    in
    assertFalse "can disable same-license commitment"
      cfg.nix-license.commitments.same-license;

  # ── Assurances defaults ───────────────────────────────────────

  assurancesDefaultFalse =
    let
      cfg = evalModule defaultUsage;
    in
    assertTrue "assurances default to false"
      (!cfg.nix-license.assurances.patent-grant
        && !cfg.nix-license.assurances.liability-coverage
        && !cfg.nix-license.assurances.warranty);

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
          license.token = ''{  "package": "nix-license", "commercial": true, "licensee": "Test Corp" }'';
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
          commitments = { same-license = false; disclose-source = false; };
          enforcement = "enforce";
        };
      };
    in
    assertTrue "proprietary company scenario"
      (!cfg.nix-license.commitments.same-license
        && !cfg.nix-license.commitments.disclose-source
        && cfg.nix-license.commitments.include-copyright);

  # ── Token verification config ─────────────────────────────────

  tokenVerificationDefaults =
    let
      cfg = evalModule defaultUsage;
    in
    assertTrue "token verification disabled by default"
      (!cfg.nix-license.tokenVerification.enable
        && cfg.nix-license.tokenVerification.requireTokens == [ ]);

  tokenRequirePackage =
    let
      cfg = evalModule (defaultUsage // {
        nix-license.tokenVerification = {
          enable = true;
          requireTokens = [ "vendor-sdk" ];
        };
      });
    in
    assertTrue "can require tokens for specific packages"
      (cfg.nix-license.tokenVerification.enable
        && builtins.elem "vendor-sdk" cfg.nix-license.tokenVerification.requireTokens);

  vendorTokenConfig =
    let
      cfg = evalModule (defaultUsage // {
        nix-license.licenses."vendor-sdk" = {
          license = "commercial";
          token = ''{ "package": "vendor-sdk", "commercial": true }'';
        };
      });
    in
    assertTrue "can set vendor token for package"
      (cfg.nix-license.licenses."vendor-sdk".token != null);

  # ── Content policy files ──────────────────────────────────────

  contentPolicyFileCreated =
    let
      cfg = evalModule (defaultUsage // { nix-license.enable = true; });
    in
    assertTrue "system content policy file created"
      (cfg.environment.etc ? "nix-license/content-policy/system.json");
}
