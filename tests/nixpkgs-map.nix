# Tests for lib/nixpkgs-map.nix
# Verifies every nixpkgs license maps to a SALT license
# and enforcement behavior is correct for all 289

{ lib, saltLicenses, saltSpdx }:

let
  nixpkgsMap = import ../lib/nixpkgs-map.nix { inherit saltLicenses saltSpdx; };
  lc = import ../lib/license-check.nix { inherit lib; };

  assertTrue = name: value:
    if value then true
    else throw "FAIL: ${name}";

  # All nixpkgs license attribute names
  allLicenseNames = builtins.attrNames lib.licenses;
  licenseCount = builtins.length allLicenseNames;

  # Map every nixpkgs license to SALT
  allMapped = builtins.listToAttrs (map
    (name: {
      inherit name;
      value = {
        nixLic = lib.licenses.${name};
        salt = nixpkgsMap.lookup lib.licenses.${name};
      };
    })
    allLicenseNames);

  unmapped = builtins.filter (name: allMapped.${name}.salt == null) allLicenseNames;

  # All 16 usage context combinations (2^4 boolean product)
  allContexts =
    let
      bools = [ true false ];
    in
    builtins.concatMap
      (cu: builtins.concatMap
        (d: builtins.concatMap
          (m: map
            (s: { commercial-use = cu; distribution = d; modifications = m; saas = s; })
            bools)
          bools)
        bools)
      bools;

  # All 6 user types
  allTypes = [ "personal" "commercial" "educational" "research" "government" "nonprofit" ];

in
{
  # ── Coverage: all 289 map to SALT ─────────────────────────────────

  hasAllLicenses = assertTrue "nixpkgs has 280+ licenses"
    (licenseCount >= 280);

  allLicensesMapped =
    if unmapped == [ ] then true
    else throw "FAIL: ${toString (builtins.length unmapped)} nixpkgs licenses not mapped to SALT: ${builtins.concatStringsSep ", " unmapped}";

  # ── Structure: all mapped results have required SALT fields ───────

  allHaveKey = assertTrue "all mapped results have key"
    (builtins.all (name: allMapped.${name}.salt ? key) allLicenseNames);

  allHaveName = assertTrue "all mapped results have name"
    (builtins.all (name: allMapped.${name}.salt ? name) allLicenseNames);

  allHaveRestrictions = assertTrue "all mapped results have restrictions"
    (builtins.all (name: allMapped.${name}.salt ? restrictions) allLicenseNames);

  # ── Restriction consistency: 289 × 16 ────────────────────────────
  #
  # For every nixpkgs license and every usage context:
  # - If SALT says restrictions.commercial-use = true and usage has commercial-use = true → must be blocked
  # - If SALT says restrictions.saas = true and usage has saas = true → must be blocked
  # - Same for distribution and modifications
  # - If SALT has no restrictions matching usage → must be allowed (unless allowed-use blocks it)

  restrictionsEnforced =
    let
      restrictionKeys = [ "commercial-use" "distribution" "modifications" "saas" ];

      check = name: ctx:
        let
          inherit (allMapped.${name}) salt;
          restrictions = salt.restrictions or { };
          result = lc.evaluateLicenseUsage ctx salt;

          # For each restriction key, check if it should cause a conflict
          activeRestrictions = builtins.filter
            (key: (restrictions.${key} or false) && (ctx.${key} or false))
            restrictionKeys;
        in
        # If any restriction is active, result must NOT be allowed
        if activeRestrictions != [ ] then
          if !result.allowed then true
          else throw "FAIL: ${name}: has active restrictions [${builtins.concatStringsSep ", " activeRestrictions}] but was allowed"
        else true;

      results = builtins.concatMap
        (name: map (ctx: check name ctx) allContexts)
        allLicenseNames;
    in
    assertTrue "restrictions enforced for all 289 × 16"
      (builtins.all (x: x) results);

  # ── No restrictions = always allowed: 289 × 16 ───────────────────

  noRestrictionsAllowed =
    let
      unrestricted = builtins.filter
        (name:
          let r = allMapped.${name}.salt.restrictions or { };
          in r == { } || builtins.all (k: !(r.${k} or false)) (builtins.attrNames r))
        allLicenseNames;

      check = name: ctx:
        let result = lc.evaluateLicenseUsage ctx allMapped.${name}.salt;
        in
        # Unrestricted licenses should be allowed (unless allowed-use blocks)
        if (allMapped.${name}.salt.allowed-use or null) == null then
          if result.allowed then true
          else throw "FAIL: ${name}: no restrictions, no allowed-use, but blocked"
        else true;

      results = builtins.concatMap
        (name: map (ctx: check name ctx) allContexts)
        unrestricted;
    in
    assertTrue "no-restriction licenses allowed for all contexts"
      (builtins.all (x: x) results);

  # ── Allowed-use enforcement: 289 × 6 types ───────────────────────

  allowedUseEnforced =
    let
      check = name: userType:
        let
          inherit (allMapped.${name}) salt;
          allowedUse = salt.allowed-use or null;
          result = lc.evaluateLicenseUsage { type = userType; } salt;
        in
        if allowedUse != null then
          if builtins.elem userType allowedUse then
          # Type is in allowed list → should be allowed
            if result.allowed then true
            else throw "FAIL: ${name}: type '${userType}' is in allowed-use but was blocked"
          else
          # Type is NOT in allowed list → should be blocked
            if !result.allowed then true
            else throw "FAIL: ${name}: type '${userType}' is NOT in allowed-use but was allowed"
        else true;

      results = builtins.concatMap
        (name: map (userType: check name userType) allTypes)
        allLicenseNames;
    in
    assertTrue "allowed-use enforced for all 289 × 6 types"
      (builtins.all (x: x) results);

  # ── Obligations triggered correctly: 289 × 16 ────────────────────

  obligationsTriggered =
    let
      check = name: ctx:
        let
          inherit (allMapped.${name}) salt;
          obligations = salt.obligations or { };
          result = lc.evaluateLicenseUsage ctx salt;

          # Count obligations that should trigger
          shouldTrigger = builtins.filter
            (oblName:
              let triggers = obligations.${oblName} or [ ];
              in builtins.any (t: t == "any" || (ctx.${t} or false)) triggers)
            (builtins.attrNames obligations);
        in
        # If obligations should trigger, they must appear in result
        if shouldTrigger != [ ] then
          if builtins.length result.obligations > 0 then true
          else throw "FAIL: ${name}: obligations [${builtins.concatStringsSep ", " shouldTrigger}] should trigger but didn't"
        else
          if builtins.length result.obligations == 0 then true
          else throw "FAIL: ${name}: no obligations should trigger but ${toString (builtins.length result.obligations)} did";

      results = builtins.concatMap
        (name: map (ctx: check name ctx) allContexts)
        allLicenseNames;
    in
    assertTrue "obligations triggered correctly for all 289 × 16"
      (builtins.all (x: x) results);

  # ── Monotonicity: adding usage flags never removes conflicts ──────

  monotonicity =
    let
      base = { commercial-use = false; distribution = false; modifications = false; saas = false; };

      check = name:
        let
          inherit (allMapped.${name}) salt;
          bR = lc.evaluateLicenseUsage base salt;
          cR = lc.evaluateLicenseUsage (base // { commercial-use = true; }) salt;
          dR = lc.evaluateLicenseUsage (base // { distribution = true; }) salt;
          mR = lc.evaluateLicenseUsage (base // { modifications = true; }) salt;
          sR = lc.evaluateLicenseUsage (base // { saas = true; }) salt;
        in
        (if cR.allowed then bR.allowed else true)
        && (if dR.allowed then bR.allowed else true)
        && (if mR.allowed then bR.allowed else true)
        && (if sR.allowed then bR.allowed else true);

      failures = builtins.filter (name: !(check name)) allLicenseNames;
    in
    if failures == [ ] then true
    else throw "FAIL: monotonicity violated for: ${builtins.concatStringsSep ", " failures}";

  # ── Empty usage = no restriction conflicts ────────────────────────

  emptyUsageNoConflicts =
    let
      failures = builtins.filter
        (name:
          let result = lc.evaluateLicenseUsage { } allMapped.${name}.salt;
          in !result.allowed)
        allLicenseNames;
    in
    if failures == [ ] then true
    else throw "FAIL: empty usage blocked for: ${builtins.concatStringsSep ", " failures}";
}
