# Assurance enforcement: 2649 × 3
# If license disclaims X and user requires X → blocked
# If no assurances required → never blocked by disclaimers

{ lib, saltLicenses }:

let
  h = import ./helpers.nix { inherit lib saltLicenses; };
  inherit (h) licenses lc assertTrue allUsageContexts licenseNames;

  assuranceKeys = {
    patent-grant = "patent-use";
    liability-coverage = "liability";
    warranty = "warranty";
  };
in
{
  noAssurancesNeverBlocks =
    let
      check = ln: ctx:
        let
          result = lc.evaluateLicenseUsage ctx licenses.${ln};
        in
        builtins.all (c: c.restriction != "assurance") (result.conflicts or [ ]);

      results = builtins.concatMap
        (ln: map (ctx: check ln ctx) allUsageContexts)
        licenseNames;
    in
    assertTrue "no assurances = no assurance blocks for all 2649 × 16"
      (builtins.all (x: x) results);

  assurancesBlockDisclaimers =
    let
      check = ln: assuranceKey:
        let
          l = licenses.${ln};
          disclaimers = l.disclaimers or [ ];
          disclaimerKey = assuranceKeys.${assuranceKey};
          hasDisclaimer = builtins.elem disclaimerKey disclaimers;
          result = lc.evaluateLicenseUsage
            { assurances = { ${assuranceKey} = true; }; }
            l;
        in
        if hasDisclaimer then
          if !result.allowed then true
          else throw "FAIL: ${ln}: disclaims '${disclaimerKey}' but assurance '${assuranceKey}' didn't block"
        else
          let assuranceConflicts = builtins.filter (c: c.restriction == "assurance") result.conflicts;
          in if assuranceConflicts == [ ] then true
          else throw "FAIL: ${ln}: no '${disclaimerKey}' disclaimer but assurance '${assuranceKey}' blocked";

      results = builtins.concatMap
        (ln: map (k: check ln k) (builtins.attrNames assuranceKeys))
        licenseNames;
    in
    assertTrue "assurances correctly block/allow for all 2649 × 3 assurance keys"
      (builtins.all (x: x) results);
}
