# Tests for lib/licenses.nix and lib/license-check.nix
# Uses SALT terminology throughout

{ lib, saltLicenses }:

let
  licenses = import ../lib/licenses.nix { inherit lib saltLicenses; };
  lc = import ../lib/license-check.nix { inherit lib; };

  assertEq = name: actual: expected:
    if actual == expected then true
    else throw "FAIL: ${name}: expected ${builtins.toJSON expected}, got ${builtins.toJSON actual}";

  assertTrue = name: value:
    if value then true
    else throw "FAIL: ${name}";

  # Usage contexts (using SALT trigger terms)
  personal = { type = "personal"; };
  commercial = { type = "commercial"; };
  educational = { type = "educational"; };
  government = { type = "government"; };
  personalDistrib = { type = "personal"; distribution = true; };
  commercialSaas = { type = "commercial"; saas = true; };
  commercialMilitary = { type = "commercial"; military = true; };

  allUsageContexts = [
    { name = "personal"; ctx = personal; }
    { name = "commercial"; ctx = commercial; }
    { name = "educational"; ctx = educational; }
    { name = "government"; ctx = government; }
    { name = "personal+distrib"; ctx = personalDistrib; }
    { name = "commercial+saas"; ctx = commercialSaas; }
    { name = "commercial+military"; ctx = commercialMilitary; }
  ];

  licenseNames = builtins.filter
    (n: !(builtins.elem n [ "_meta" "allRestrictions" "allObligations" "allGrants" "allDisclaimers" ]))
    (builtins.attrNames licenses);

in
{
  # ── Existence ───────────────────────────────────────────────────

  hasMit = assertTrue "MIT exists" (licenses ? mit);
  hasGpl3 = assertTrue "GPL 3.0 exists" (builtins.hasAttr "gpl-3.0" licenses);
  hasAgpl3 = assertTrue "AGPL 3.0 exists" (builtins.hasAttr "agpl-3.0" licenses);
  hasCcByNc = assertTrue "CC-BY-NC-4.0 exists" (builtins.hasAttr "cc-by-nc-4.0" licenses);
  hasCount = assertTrue "2600+ licenses" (builtins.length licenseNames >= 2600);

  # ── Free/unfree ─────────────────────────────────────────────────

  mitIsFree = assertTrue "MIT is free" licenses.mit.free;

  # ── Permissive allows all ───────────────────────────────────────

  mitAllowsAll = assertTrue "MIT allows all"
    (builtins.all (u: (lc.evaluateLicenseUsage u.ctx licenses.mit).allowed) allUsageContexts);

  # ── Copyleft allows all but has obligations on distribution ─────

  gpl3AllowsAll = assertTrue "GPL 3.0 allows all"
    (builtins.all (u: (lc.evaluateLicenseUsage u.ctx licenses."gpl-3.0").allowed) allUsageContexts);

  gpl3DistribObligations =
    let result = lc.evaluateLicenseUsage personalDistrib licenses."gpl-3.0";
    in assertTrue "GPL 3.0 triggers obligations on distribution"
      (builtins.length result.obligations > 0);

  gpl3HasDiscloseSource =
    let result = lc.evaluateLicenseUsage personalDistrib licenses."gpl-3.0";
    in assertTrue "GPL 3.0 triggers disclose-source"
      (builtins.any (o: o.obligation == "disclose-source") result.obligations);

  gpl3HasSameLicense =
    let result = lc.evaluateLicenseUsage personalDistrib licenses."gpl-3.0";
    in assertTrue "GPL 3.0 triggers same-license"
      (builtins.any (o: o.obligation == "same-license") result.obligations);

  gpl3PersonalNoObligations =
    let result = lc.evaluateLicenseUsage personal licenses."gpl-3.0";
    in assertEq "GPL 3.0 no obligations for personal"
      (builtins.length result.obligations) 0;

  # ── AGPL triggers on SaaS ───────────────────────────────────────

  agpl3SaasObligations =
    let result = lc.evaluateLicenseUsage commercialSaas licenses."agpl-3.0";
    in assertTrue "AGPL 3.0 triggers disclose-source on SaaS"
      (builtins.any (o: o.obligation == "disclose-source") result.obligations);

  # ── Source availability ─────────────────────────────────────────

  freePassesSourceCheck =
    let result = lc.evaluateSourceAvailability false licenses.mit;
    in assertTrue "free passes source check" result.allowed;

  # ── Cross-product ───────────────────────────────────────────────

  crossProductValid =
    let
      results = builtins.concatMap
        (ln: map
          (u:
            let result = lc.evaluateLicenseUsage u.ctx licenses.${ln};
            in result ? allowed && result ? conflicts && result ? obligations
          )
          allUsageContexts)
        licenseNames;
    in
    assertTrue "all combinations valid" (builtins.all (x: x) results);

  # ── Structure ───────────────────────────────────────────────────

  allHaveRestrictions = assertTrue "all have restrictions"
    (builtins.all (n: licenses.${n} ? restrictions) licenseNames);

  allHaveObligations = assertTrue "all have obligations"
    (builtins.all (n: licenses.${n} ? obligations) licenseNames);

  allHaveFullName = assertTrue "all have fullName"
    (builtins.all (n: licenses.${n} ? fullName) licenseNames);
}
