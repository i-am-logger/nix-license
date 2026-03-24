# Monotonicity: adding usage flags never removes conflicts
# Also: empty usage = no conflicts

{ lib, saltLicenses }:

let
  h = import ./helpers.nix { inherit lib saltLicenses; };
  inherit (h) licenses lc assertTrue licenseNames;
in
{
  emptyUsageNoConflicts = assertTrue "empty usage = no conflicts"
    (builtins.all (ln: (lc.evaluateLicenseUsage { } licenses.${ln}).allowed) licenseNames);

  addingUsageNeverRemovesConflicts =
    let
      base = { commercial-use = false; distribution = false; modifications = false; saas = false; };
    in
    assertTrue "adding usage flags never removes conflicts"
      (builtins.all
        (ln:
          let
            l = licenses.${ln};
            bR = lc.evaluateLicenseUsage base l;
            cR = lc.evaluateLicenseUsage (base // { commercial-use = true; }) l;
            dR = lc.evaluateLicenseUsage (base // { distribution = true; }) l;
            mR = lc.evaluateLicenseUsage (base // { modifications = true; }) l;
            sR = lc.evaluateLicenseUsage (base // { saas = true; }) l;
          in
          (if cR.allowed then bR.allowed else true)
          && (if dR.allowed then bR.allowed else true)
          && (if mR.allowed then bR.allowed else true)
          && (if sR.allowed then bR.allowed else true)
        )
        licenseNames);
}
