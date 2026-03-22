# Tests for modules/default.nix (standalone NixOS module)
# Run via: nix eval .#checks.<system>.module-standalone

{ lib, oarsSpec }:

let
  # Evaluate a NixOS module with nix-license
  evalModule = extraConfig:
    (lib.evalModules {
      modules = [
        ../modules/default.nix
        {
          # Stub nixpkgs.config since we're not in a full NixOS eval
          options.nixpkgs.config = lib.mkOption {
            type = lib.types.attrs;
            default = { };
          };
        }
        { _module.args.oarsSpec = oarsSpec; }
        extraConfig
      ];
    }).config;

  # Test helpers
  assertEq = name: actual: expected:
    if actual == expected then true
    else throw "FAIL: ${name}: expected ${builtins.toJSON expected}, got ${builtins.toJSON actual}";

  assertTrue = name: value:
    if value then true
    else throw "FAIL: ${name}: expected true";

  assertFalse = name: value:
    if !value then true
    else throw "FAIL: ${name}: expected false";

in
{
  # ── Default values ──────────────────────────────────────────────

  defaultDisabled =
    let cfg = evalModule { };
    in assertFalse "disabled by default" cfg.nix-license.enable;

  defaultAllowClosedSource =
    let cfg = evalModule { };
    in assertTrue "allowClosedSource defaults to true" cfg.nix-license.allowClosedSource;

  defaultUsagePersonal =
    let cfg = evalModule { };
    in assertEq "usage defaults to personal" cfg.nix-license.usage.type "personal";

  defaultNoRedistribution =
    let cfg = evalModule { };
    in assertFalse "redistribution defaults to false" cfg.nix-license.usage.redistribution;

  defaultNoSaas =
    let cfg = evalModule { };
    in assertFalse "saas defaults to false" cfg.nix-license.usage.saas;

  defaultNoMilitary =
    let cfg = evalModule { };
    in assertFalse "military defaults to false" cfg.nix-license.usage.military;

  defaultInternal =
    let cfg = evalModule { };
    in assertTrue "internal defaults to true" cfg.nix-license.usage.internal;

  defaultEnforceWarn =
    let cfg = evalModule { };
    in assertEq "enforcement defaults to warn" cfg.nix-license.enforcement "warn";

  defaultAllowUnrated =
    let cfg = evalModule { };
    in assertTrue "allowUnrated defaults to true" cfg.nix-license.contentPolicy.allowUnrated;

  defaultNoPreset =
    let cfg = evalModule { };
    in assertEq "preset defaults to null" cfg.nix-license.contentPolicy.preset null;

  defaultNoLicenses =
    let cfg = evalModule { };
    in assertEq "licenses defaults to empty" cfg.nix-license.licenses { };

  # ── Content policy category defaults ────────────────────────────

  defaultCategoriesIntense =
    let
      cfg = evalModule { };
      types = import ../lib/types.nix { inherit lib oarsSpec; };
    in
    assertTrue
      "all categories default to intense"
      (builtins.all
        (cat: cfg.nix-license.contentPolicy.${cat} == "intense")
        types.oarsCategories);

  # ── Custom configuration ────────────────────────────────────────

  customUsageCommercial =
    let
      cfg = evalModule {
        nix-license.usage.type = "commercial";
      };
    in
    assertEq "custom usage type" cfg.nix-license.usage.type "commercial";

  customMilitary =
    let
      cfg = evalModule {
        nix-license.usage.military = true;
      };
    in
    assertTrue "custom military" cfg.nix-license.usage.military;

  customEnforcement =
    let
      cfg = evalModule {
        nix-license.enforcement = "enforce";
      };
    in
    assertEq "custom enforcement" cfg.nix-license.enforcement "enforce";

  customContentPolicy =
    let
      cfg = evalModule {
        nix-license.contentPolicy.violence-cartoon = "mild";
      };
    in
    assertEq "custom content policy" cfg.nix-license.contentPolicy.violence-cartoon "mild";

  customAllowUnrated =
    let
      cfg = evalModule {
        nix-license.contentPolicy.allowUnrated = false;
      };
    in
    assertFalse "custom allowUnrated" cfg.nix-license.contentPolicy.allowUnrated;

  customClosedSource =
    let
      cfg = evalModule {
        nix-license.allowClosedSource = false;
      };
    in
    assertFalse "custom allowClosedSource" cfg.nix-license.allowClosedSource;

  # ── License overrides ──────────────────────────────────────────

  licenseOverride =
    let
      cfg = evalModule {
        nix-license.licenses."vendor-sdk" = {
          license = "commercial";
          licenseId = "LIC-2024-12345";
          expiresAt = "2025-06-15";
        };
      };
    in
    assertEq "license override" cfg.nix-license.licenses."vendor-sdk".license "commercial";

  licenseOverrideId =
    let
      cfg = evalModule {
        nix-license.licenses."vendor-sdk" = {
          license = "commercial";
          licenseId = "LIC-2024-12345";
        };
      };
    in
    assertEq "license override id" cfg.nix-license.licenses."vendor-sdk".licenseId "LIC-2024-12345";

  licenseOverrideDefaults =
    let
      cfg = evalModule {
        nix-license.licenses."vendor-sdk" = {
          license = "commercial";
        };
      };
    in
    assertEq "license token defaults to null" cfg.nix-license.licenses."vendor-sdk".tokenFile null;

  # ── Enabled wires to nixpkgs.config ────────────────────────────

  enabledWiresAllowUnfree =
    let
      cfg = evalModule {
        nix-license = {
          enable = true;
          allowClosedSource = true;
        };
      };
    in
    assertTrue "enable wires allowUnfree" cfg.nixpkgs.config.allowUnfree;

  enabledWiresAllowUnfreeFalse =
    let
      cfg = evalModule {
        nix-license = {
          enable = true;
          allowClosedSource = false;
        };
      };
    in
    assertFalse "enable wires allowUnfree false" cfg.nixpkgs.config.allowUnfree;

  # ── Usage type variations ──────────────────────────────────────

  usagePersonal =
    let cfg = evalModule { nix-license.usage.type = "personal"; };
    in assertEq "personal" cfg.nix-license.usage.type "personal";

  usageCommercial =
    let cfg = evalModule { nix-license.usage.type = "commercial"; };
    in assertEq "commercial" cfg.nix-license.usage.type "commercial";

  usageEducational =
    let cfg = evalModule { nix-license.usage.type = "educational"; };
    in assertEq "educational" cfg.nix-license.usage.type "educational";

  usageGovernment =
    let cfg = evalModule { nix-license.usage.type = "government"; };
    in assertEq "government" cfg.nix-license.usage.type "government";

  # ── Combined scenarios ──────────────────────────────────────────

  scenarioCompany =
    let
      cfg = evalModule {
        nix-license = {
          enable = true;
          allowClosedSource = true;
          usage = {
            type = "commercial";
            saas = true;
          };
          enforcement = "enforce";
        };
      };
    in
    assertTrue "company scenario"
      (cfg.nix-license.usage.type == "commercial"
        && cfg.nix-license.usage.saas
        && cfg.nix-license.enforcement == "enforce"
        && cfg.nixpkgs.config.allowUnfree);

  scenarioSchool =
    let
      cfg = evalModule {
        nix-license = {
          enable = true;
          allowClosedSource = false;
          usage = {
            type = "educational";
            research = true;
            nonprofit = true;
          };
          contentPolicy = {
            violence-realistic = "none";
            money-gambling = "none";
            social-chat = "none";
            allowUnrated = false;
          };
        };
      };
    in
    assertTrue "school scenario"
      (cfg.nix-license.usage.type == "educational"
        && cfg.nix-license.usage.research
        && cfg.nix-license.usage.nonprofit
        && !cfg.nix-license.allowClosedSource
        && cfg.nix-license.contentPolicy.violence-realistic == "none"
        && !cfg.nix-license.contentPolicy.allowUnrated);

  scenarioDefenseContractor =
    let
      cfg = evalModule {
        nix-license = {
          enable = true;
          allowClosedSource = true;
          usage = {
            type = "commercial";
            military = true;
          };
        };
      };
    in
    assertTrue "defense contractor scenario"
      (cfg.nix-license.usage.type == "commercial"
        && cfg.nix-license.usage.military);
}
