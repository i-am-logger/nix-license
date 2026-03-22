# Tests for modules/default.nix (standalone NixOS module)

{ lib, oarsSpec }:

let
  evalModule = extraConfig:
    (lib.evalModules {
      modules = [
        ../modules/default.nix
        {
          options.nixpkgs.config = lib.mkOption {
            type = lib.types.attrs;
            default = { };
          };
        }
        { _module.args.oarsSpec = oarsSpec; }
        extraConfig
      ];
    }).config;

  # Default usage for tests (all fields required, no defaults)
  defaultUsage = {
    nix-license.usage = {
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
  # ── Defaults ────────────────────────────────────────────────────

  defaultDisabled =
    let cfg = evalModule defaultUsage;
    in assertFalse "disabled by default" cfg.nix-license.enable;

  defaultAllowClosedSource =
    let cfg = evalModule defaultUsage;
    in assertTrue "allowClosedSource defaults to true" cfg.nix-license.allowClosedSource;

  defaultEnforceWarn =
    let cfg = evalModule defaultUsage;
    in assertEq "enforcement defaults to warn" cfg.nix-license.enforcement "warn";

  defaultAllowUnrated =
    let cfg = evalModule defaultUsage;
    in assertTrue "allowUnrated defaults to true" cfg.nix-license.contentPolicy.allowUnrated;

  defaultNoLicenses =
    let cfg = evalModule defaultUsage;
    in assertEq "licenses defaults to empty" cfg.nix-license.licenses { };

  # ── Usage is explicit ───────────────────────────────────────────

  usageCommercial =
    let
      cfg = evalModule {
        nix-license.usage = {
          commercial-use = true;
          distribution = false;
          modifications = false;
          saas = false;
        };
      };
    in
    assertTrue "commercial-use set" cfg.nix-license.usage.commercial-use;

  usageSaas =
    let
      cfg = evalModule {
        nix-license.usage = {
          commercial-use = true;
          distribution = true;
          modifications = true;
          saas = true;
        };
      };
    in
    assertTrue "saas set" cfg.nix-license.usage.saas;

  # ── Content policy categories ───────────────────────────────────

  defaultCategoriesIntense =
    let
      cfg = evalModule defaultUsage;
      types = import ../lib/types.nix { inherit lib oarsSpec; };
    in
    assertTrue "all categories default to intense"
      (builtins.all
        (cat: cfg.nix-license.contentPolicy.${cat} == "intense")
        types.oarsCategories);

  customContentPolicy =
    let
      cfg = evalModule (defaultUsage // {
        nix-license.contentPolicy.violence-cartoon = "mild";
      });
    in
    assertEq "custom content policy" cfg.nix-license.contentPolicy.violence-cartoon "mild";

  # ── Enabled wires to nixpkgs.config ─────────────────────────────

  enabledWiresAllowUnfree =
    let
      cfg = evalModule (defaultUsage // {
        nix-license = {
          enable = true;
          allowClosedSource = true;
          usage = {
            commercial-use = false;
            distribution = false;
            modifications = false;
            saas = false;
          };
        };
      });
    in
    assertTrue "enable wires allowUnfree" cfg.nixpkgs.config.allowUnfree;

  enabledWiresAllowUnfreeFalse =
    let
      cfg = evalModule (defaultUsage // {
        nix-license = {
          enable = true;
          allowClosedSource = false;
          usage = {
            commercial-use = false;
            distribution = false;
            modifications = false;
            saas = false;
          };
        };
      });
    in
    assertFalse "enable wires allowUnfree false" cfg.nixpkgs.config.allowUnfree;

  # ── Scenarios ───────────────────────────────────────────────────

  scenarioCompany =
    let
      cfg = evalModule {
        nix-license = {
          enable = true;
          allowClosedSource = true;
          usage = {
            commercial-use = true;
            distribution = false;
            modifications = true;
            saas = false;
          };
          enforcement = "enforce";
        };
      };
    in
    assertTrue "company scenario"
      (cfg.nix-license.usage.commercial-use
        && cfg.nix-license.enforcement == "enforce"
        && cfg.nixpkgs.config.allowUnfree);

  scenarioSaas =
    let
      cfg = evalModule {
        nix-license = {
          enable = true;
          allowClosedSource = true;
          usage = {
            commercial-use = true;
            distribution = true;
            modifications = true;
            saas = true;
          };
        };
      };
    in
    assertTrue "saas scenario"
      (cfg.nix-license.usage.saas
        && cfg.nix-license.usage.commercial-use
        && cfg.nix-license.usage.distribution);
}
