# Obligation triggers: 2649 × 16
# Obligations fire exactly when their trigger keys match usage

{ lib, saltLicenses }:

let
  h = import ./helpers.nix { inherit lib saltLicenses; };
  inherit (h) licenses lc assertTrue allUsageContexts licenseNames;
in
{
  obligationsTriggered =
    let
      check = ln: ctx:
        let
          l = licenses.${ln};
          obligations = l.obligations or { };
          result = lc.evaluateLicenseUsage ctx l;

          shouldTrigger = builtins.filter
            (oblName:
              let triggers = obligations.${oblName} or [ ];
              in builtins.any (t: t == "any" || (ctx.${t} or false)) triggers)
            (builtins.attrNames obligations);
        in
        if shouldTrigger != [ ] then
          if builtins.length result.obligations > 0 then true
          else throw "FAIL: ${ln}: obligations [${builtins.concatStringsSep ", " shouldTrigger}] should trigger but didn't"
        else
          if builtins.length result.obligations == 0 then true
          else throw "FAIL: ${ln}: no obligations should trigger but ${toString (builtins.length result.obligations)} did";

      results = builtins.concatMap
        (ln: map (ctx: check ln ctx) allUsageContexts)
        licenseNames;
    in
    assertTrue "obligations triggered correctly for all 2649 × 16"
      (builtins.all (x: x) results);
}
