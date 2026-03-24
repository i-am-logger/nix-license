# Allowed-use enforcement: 2649 × 6 types
# If license specifies who can use it and user type isn't in list → blocked

{ lib, saltLicenses }:

let
  h = import ./helpers.nix { inherit lib saltLicenses; };
  inherit (h) licenses lc assertTrue licenseNames;

  allTypes = [ "personal" "commercial" "educational" "research" "government" "nonprofit" ];
in
{
  allowedUseEnforced =
    let
      check = ln: userType:
        let
          l = licenses.${ln};
          allowedUse = l.allowed-use or null;
          result = lc.evaluateLicenseUsage { type = userType; } l;
        in
        if allowedUse != null then
          if builtins.elem userType allowedUse then
            if result.allowed then true
            else throw "FAIL: ${ln}: type '${userType}' in allowed-use but blocked"
          else
            if !result.allowed then true
            else throw "FAIL: ${ln}: type '${userType}' not in allowed-use but allowed"
        else true;

      results = builtins.concatMap
        (ln: map (userType: check ln userType) allTypes)
        licenseNames;
    in
    assertTrue "allowed-use enforced for all 2649 × 6 types"
      (builtins.all (x: x) results);
}
