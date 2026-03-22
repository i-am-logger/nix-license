{ lib, oarsSpec, saltLicenses ? { }, saltSpdx ? { } }:

let
  evalModule = extraConfig:
    (lib.evalModules {
      modules = [
        ../modules/default.nix
        {
          options.nixpkgs.config = lib.mkOption { type = lib.types.attrs; default = { }; };
          options.assertions = lib.mkOption { type = lib.types.listOf lib.types.attrs; default = [ ]; };
        }
        { _module.args = { inherit oarsSpec saltLicenses saltSpdx; }; }
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

  warnModeAllowsUnfree =
    let cfg = evalModule (defaultUsage // { nix-license.enable = true; });
    in assertTrue "warn mode sets allowUnfree=true" cfg.nixpkgs.config.allowUnfree;

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
        && !cfg.nixpkgs.config.allowUnfree);

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
}
