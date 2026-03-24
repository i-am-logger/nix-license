# Commitment enforcement: 2649
# If obligation triggers and user can't commit → blocked
# If all commitments = true → never blocked by commitments

{ lib, saltLicenses }:

let
  h = import ./helpers.nix { inherit lib saltLicenses; };
  inherit (h) licenses lc assertTrue allUsageContexts licenseNames;

  allObligationKeys = [
    "include-copyright"
    "disclose-source"
    "same-license"
    "same-license--file"
    "same-license--library"
    "document-changes"
    "network-use-disclose"
  ];
in
{
  commitmentsBlockWhenCantFulfill =
    let
      check = ln:
        let
          l = licenses.${ln};
          obligations = l.obligations or { };
          oblKeys = builtins.attrNames obligations;
        in
        builtins.all
          (oblName:
            let
              triggers = obligations.${oblName} or [ ];
              triggerCtx = builtins.foldl'
                (acc: t:
                  if acc != null then acc
                  else if t == "any" then { ${t} = true; }
                  else { ${t} = true; })
                null
                triggers;
            in
            if triggerCtx == null || !builtins.elem oblName allObligationKeys then true
            else
              let
                ctx = triggerCtx // { commitments = { ${oblName} = false; }; };
                result = lc.evaluateLicenseUsage ctx l;
              in
              if !result.allowed then true
              else throw "FAIL: ${ln}: obligation '${oblName}' triggered but commitment=false didn't block"
          )
          oblKeys;

      results = map check licenseNames;
    in
    assertTrue "commitments block for all 2649 when can't fulfill"
      (builtins.all (x: x) results);

  commitmentsAllowWhenCanFulfill =
    let
      check = ln: ctx:
        let
          l = licenses.${ln};
          ctxWithCommitments = ctx // {
            commitments = {
              include-copyright = true;
              disclose-source = true;
              same-license = true;
              same-license--file = true;
              same-license--library = true;
              document-changes = true;
              network-use-disclose = true;
            };
          };
          result = lc.evaluateLicenseUsage ctxWithCommitments l;
        in
        if !result.allowed then
          builtins.all (c: c.restriction != "commitment") result.conflicts
        else true;

      results = builtins.concatMap
        (ln: map (ctx: check ln ctx) allUsageContexts)
        licenseNames;
    in
    assertTrue "commitments=true never blocks for all 2649 × 16"
      (builtins.all (x: x) results);
}
