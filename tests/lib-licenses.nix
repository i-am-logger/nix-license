# Tests for lib/salt.nix and lib/license-check.nix
# Usage fields match SALT restriction keys

{ lib, saltLicenses }:

let
  licenses = import ../lib/salt.nix { inherit lib saltLicenses; };
  lc = import ../lib/licensing/check.nix { };

  assertEq = name: actual: expected:
    if actual == expected then true
    else throw "FAIL: ${name}: expected ${builtins.toJSON expected}, got ${builtins.toJSON actual}";

  assertTrue = name: value:
    if value then true
    else throw "FAIL: ${name}";

  # Usage contexts — flat booleans matching SALT restriction keys
  personal = { type = "personal"; };
  commercial = { type = "commercial"; commercial-use = true; };
  distributing = { type = "personal"; distribution = true; };
  commercialDistrib = { type = "commercial"; commercial-use = true; distribution = true; };
  commercialSaas = { type = "commercial"; commercial-use = true; saas = true; };
  modifying = { type = "personal"; modifications = true; };

  allUsageContexts = [
    { name = "personal"; ctx = personal; }
    { name = "commercial"; ctx = commercial; }
    { name = "distributing"; ctx = distributing; }
    { name = "commercial+distrib"; ctx = commercialDistrib; }
    { name = "commercial+saas"; ctx = commercialSaas; }
    { name = "modifying"; ctx = modifying; }
  ];

  licenseNames = builtins.filter
    (n: !(builtins.elem n [ "_meta" "allRestrictions" "allObligations" "allGrants" "allDisclaimers" ]))
    (builtins.attrNames licenses);

in
{
  # ── Existence ───────────────────────────────────────────────────

  hasMit = assertTrue "MIT exists" (licenses ? mit);
  hasGpl3 = assertTrue "GPL 3.0 exists" (builtins.hasAttr "gpl-3.0" licenses);
  hasCcByNc = assertTrue "CC-BY-NC-4.0 exists" (builtins.hasAttr "cc-by-nc-4.0" licenses);
  hasElastic = assertTrue "Elastic v2 exists" (builtins.hasAttr "elastic-license-v2" licenses);
  hasCount = assertTrue "2600+ licenses" (builtins.length licenseNames >= 2600);

  # ── Free/unfree ─────────────────────────────────────────────────

  mitIsFree = assertTrue "MIT is free" licenses.mit.free;

  # ── Permissive allows everything ────────────────────────────────

  mitAllowsAll = assertTrue "MIT allows all"
    (builtins.all (u: (lc.evaluateLicenseUsage u.ctx licenses.mit).allowed) allUsageContexts);

  # ── Commercial restriction ─────────────────────────────────────

  ccByNcBlocksCommercial =
    let result = lc.evaluateLicenseUsage commercial licenses."cc-by-nc-4.0";
    in assertTrue "CC-BY-NC blocks commercial-use"
      (!result.allowed);

  ccByNcAllowsPersonal =
    let result = lc.evaluateLicenseUsage personal licenses."cc-by-nc-4.0";
    in assertTrue "CC-BY-NC allows personal"
      result.allowed;

  # ── SaaS restriction ────────────────────────────────────────────

  elasticBlocksSaas =
    let result = lc.evaluateLicenseUsage { saas = true; } licenses."elastic-license-v2";
    in assertTrue "Elastic blocks saas"
      (!result.allowed);

  elasticAllowsPersonal =
    let result = lc.evaluateLicenseUsage personal licenses."elastic-license-v2";
    in assertTrue "Elastic allows personal"
      result.allowed;

  # ── Copyleft obligations on distribution ────────────────────────

  gpl3DistribObligations =
    let result = lc.evaluateLicenseUsage distributing licenses."gpl-3.0";
    in assertTrue "GPL 3.0 has obligations on distribution"
      (builtins.length result.obligations > 0);

  gpl3PersonalNoObligations =
    let result = lc.evaluateLicenseUsage personal licenses."gpl-3.0";
    in assertEq "GPL 3.0 no obligations for personal"
      (builtins.length result.obligations) 0;

  # ── Source availability ─────────────────────────────────────────


  # ── Allowed-use (allowlist) ─────────────────────────────────────

  allowedUseBlocksWrongType =
    let
      academicLicense = { restrictions = { }; allowed-use = [ "educational" "research" ]; };
      result = lc.evaluateLicenseUsage { type = "commercial"; } academicLicense;
    in
    assertTrue "academic license blocks commercial type" (!result.allowed);

  allowedUseAllowsCorrectType =
    let
      academicLicense = { restrictions = { }; allowed-use = [ "educational" "research" ]; };
      result = lc.evaluateLicenseUsage { type = "educational"; } academicLicense;
    in
    assertTrue "academic license allows educational type" result.allowed;

  noAllowedUseMeansNoTypeCheck =
    let
      normalLicense = { restrictions = { }; };
      result = lc.evaluateLicenseUsage { type = "commercial"; } normalLicense;
    in
    assertTrue "no allowed-use means any type is fine" result.allowed;

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

  # ── Commitments ─────────────────────────────────────────────────

  commitmentBlocksCopyleft =
    let
      result = lc.evaluateLicenseUsage
        { distribution = true; commitments = { same-license = false; }; }
        licenses."gpl-3.0";
    in
    assertTrue "commitment blocks GPL when can't do same-license"
      (!result.allowed);

  commitmentAllowsWhenCanFulfill =
    let
      result = lc.evaluateLicenseUsage
        { distribution = true; commitments = { same-license = true; }; }
        licenses."gpl-3.0";
    in
    assertTrue "commitment allows GPL when can do same-license"
      result.allowed;

  commitmentOnlyChecksTriggered =
    let
      result = lc.evaluateLicenseUsage
        { type = "personal"; commitments = { same-license = false; }; }
        licenses."gpl-3.0";
    in
    assertTrue "commitment ignored when obligation doesn't trigger"
      result.allowed;

  # ── Assurances ─────────────────────────────────────────────────

  assuranceBlocksDisclaimer =
    let
      license = { restrictions = { }; disclaimers = [ "patent-use" ]; };
      result = lc.evaluateLicenseUsage
        { assurances = { patent-grant = true; }; }
        license;
    in
    assertTrue "assurance blocks license disclaiming patent-use"
      (!result.allowed);

  assuranceAllowsWhenNotDisclaimed =
    let
      license = { restrictions = { }; disclaimers = [ ]; };
      result = lc.evaluateLicenseUsage
        { assurances = { patent-grant = true; }; }
        license;
    in
    assertTrue "assurance allows when not disclaimed"
      result.allowed;

  assuranceDefaultNoBlock =
    let
      license = { restrictions = { }; disclaimers = [ "patent-use" "liability" "warranty" ]; };
      result = lc.evaluateLicenseUsage { } license;
    in
    assertTrue "no assurances = no blocking on disclaimers"
      result.allowed;

  # ── Structure ───────────────────────────────────────────────────

  allHaveRestrictions = assertTrue "all have restrictions"
    (builtins.all (n: licenses.${n} ? restrictions) licenseNames);

  allHaveObligations = assertTrue "all have obligations"
    (builtins.all (n: licenses.${n} ? obligations) licenseNames);
}
