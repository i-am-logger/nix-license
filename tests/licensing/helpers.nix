# Shared test helpers for licensing tests
{ lib, saltLicenses }:

let
  licenses = import ../../lib/salt.nix { inherit lib saltLicenses; };
  lc = import ../../lib/licensing/check.nix { };

  assertTrue = name: value:
    if value then true
    else throw "FAIL: ${name}";

  boolProduct = keys:
    let
      go = remaining:
        if remaining == [ ] then [{ }]
        else
          let
            key = builtins.head remaining;
            rest = go (builtins.tail remaining);
          in
          builtins.concatMap (r: [ (r // { ${key} = true; }) (r // { ${key} = false; }) ]) rest;
    in
    go keys;

  allUsageContexts = boolProduct [ "commercial-use" "distribution" "modifications" "saas" ];

  licenseNames = builtins.filter
    (n: !(builtins.elem n [ "_meta" "allRestrictions" "allObligations" "allGrants" "allDisclaimers" ]))
    (builtins.attrNames licenses);
in
{
  inherit licenses lc assertTrue boolProduct allUsageContexts licenseNames;
}
