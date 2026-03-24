# Restriction enforcement: 2649 × 16
# If a SALT license restricts an activity and usage includes it → blocked

{ lib, saltLicenses }:

let
  h = import ./helpers.nix { inherit lib saltLicenses; };
  inherit (h) licenses lc assertTrue allUsageContexts licenseNames;

  restrictionKeys = [ "commercial-use" "distribution" "modifications" "saas" ];
in
{
  restrictionsEnforced =
    let
      check = ln: ctx:
        let
          l = licenses.${ln};
          restrictions = l.restrictions or { };
          result = lc.evaluateLicenseUsage ctx l;
          activeRestrictions = builtins.filter
            (key: (restrictions.${key} or false) && (ctx.${key} or false))
            restrictionKeys;
        in
        if activeRestrictions != [ ] then
          if !result.allowed then true
          else throw "FAIL: ${ln}: restrictions [${builtins.concatStringsSep ", " activeRestrictions}] active but allowed"
        else true;

      results = builtins.concatMap
        (ln: map (ctx: check ln ctx) allUsageContexts)
        licenseNames;
    in
    assertTrue "restrictions enforced for all 2649 × 16"
      (builtins.all (x: x) results);

  noRestrictionsUniversallyAllowed = assertTrue "no restrictions = universally allowed"
    (builtins.all
      (ln:
        let l = licenses.${ln};
        in if l.restrictions == { } then
          builtins.all (ctx: (lc.evaluateLicenseUsage ctx l).allowed) allUsageContexts
        else true)
      licenseNames);
}
