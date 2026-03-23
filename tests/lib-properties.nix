# Domain model guarantees — uses SALT terminology

{ lib, oarsSpec, saltLicenses }:

let
  cr = import ../lib/content-rating.nix { inherit lib oarsSpec; };
  types = import ../lib/types.nix { inherit lib oarsSpec; };
  licenses = import ../lib/salt.nix { inherit lib saltLicenses; };
  lc = import ../lib/license-check.nix { };

  assertTrue = name: value:
    if value then true
    else throw "FAIL: ${name}";

  assertEq = name: actual: expected:
    if actual == expected then true
    else throw "FAIL: ${name}: expected ${builtins.toJSON expected}, got ${builtins.toJSON actual}";

  intensities = [ "none" "mild" "moderate" "intense" ];
  pairs = xs: builtins.concatMap (a: map (b: { inherit a b; }) xs) xs;
  triples = xs: builtins.concatMap (a: builtins.concatMap (b: map (c: { inherit a b c; }) xs) xs) xs;
  boolProduct = keys:
    let
      go = remaining:
        if remaining == [ ] then [{ }]
        else
          let key = builtins.head remaining; rest = go (builtins.tail remaining);
          in builtins.concatMap (r: [ (r // { ${key} = true; }) (r // { ${key} = false; }) ]) rest;
    in
    go keys;

  allUsageContexts =
    boolProduct [ "commercial-use" "distribution" "modifications" "saas" ];

  licenseNames = builtins.filter
    (n: !(builtins.elem n [ "_meta" "allRestrictions" "allObligations" "allGrants" "allDisclaimers" ]))
    (builtins.attrNames licenses);

in
{
  # ── Severity ────────────────────────────────────────────────────

  severityReflexive = assertTrue "severity reflexive"
    (builtins.all (a: cr.severityAllowed a a) intensities);

  severityTransitive = assertTrue "severity transitive"
    (builtins.all ({ a, b, c }: if cr.severityAllowed a b && cr.severityAllowed b c then cr.severityAllowed a c else true) (triples intensities));

  severityTotal = assertTrue "severity total"
    (builtins.all ({ a, b }: cr.severityAllowed a b || cr.severityAllowed b a) (pairs intensities));

  # ── Content policy hierarchy ────────────────────────────────────

  childMoreRestrictiveThanTeen = assertTrue "child < teen"
    (builtins.all (cat: cr.severityAllowed types.policyPresets.child.${cat} types.policyPresets.teen.${cat}) types.oarsCategories);

  relaxingPolicyNeverRemovesAccess = assertTrue "relaxing never removes access"
    (builtins.all
      (rating:
        let
          c = (cr.evaluateContentRating "child" rating).allowed;
          t = (cr.evaluateContentRating "teen" rating).allowed;
          u = (cr.evaluateContentRating "unrestricted" rating).allowed;
        in
        (if c then t && u else true) && (if t then u else true)
      )
      (map (level: builtins.listToAttrs (map (cat: { name = cat; value = level; }) types.oarsCategories)) intensities));

  resolvingPolicyIsStable = assertTrue "resolving policy is stable"
    (builtins.all (p: cr.resolveContentPolicy p == cr.resolveContentPolicy (cr.resolveContentPolicy p))
      [ "child" "teen" "unrestricted" ]);

  # ── License restrictions ────────────────────────────────────────

  noUsageNoConflicts = assertTrue "empty usage = no conflicts"
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

  noRestrictionsUniversallyAllowed = assertTrue "no restrictions = universally allowed"
    (builtins.all
      (ln:
        let l = licenses.${ln};
        in if l.restrictions == { } then
          builtins.all (ctx: (lc.evaluateLicenseUsage ctx l).allowed) allUsageContexts
        else true)
      licenseNames);

  # ── Restriction enforcement: 2600+ × 16 ────────────────────────
  #
  # If a SALT license restricts an activity and usage includes that activity → blocked

  restrictionsEnforced =
    let
      restrictionKeys = [ "commercial-use" "distribution" "modifications" "saas" ];

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
    assertTrue "restrictions enforced for all 2600+ × 16"
      (builtins.all (x: x) results);

  # ── Allowed-use enforcement: 2600+ × 6 types ─────────────────

  allowedUseEnforced =
    let
      allTypes = [ "personal" "commercial" "educational" "research" "government" "nonprofit" ];

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
    assertTrue "allowed-use enforced for all 2600+ × 6 types"
      (builtins.all (x: x) results);

  # ── Obligation triggers: 2600+ × 16 ──────────────────────────
  #
  # Obligations fire exactly when their trigger keys match usage

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
    assertTrue "obligations triggered correctly for all 2600+ × 16"
      (builtins.all (x: x) results);

  # ── Commitments: 2600+ ─────────────────────────────────────────
  #
  # If an obligation triggers and the user can't commit → blocked
  # If an obligation triggers and the user can commit → allowed
  # If no obligation triggers, commitment value doesn't matter

  commitmentsBlockWhenCantFulfill =
    let
      allObligationKeys = [
        "include-copyright"
        "disclose-source"
        "same-license"
        "same-license--file"
        "same-license--library"
        "document-changes"
        "network-use-disclose"
      ];

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
              # Find a context that triggers this obligation
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
                # With commitment = false, should block
                ctx = triggerCtx // { commitments = { ${oblName} = false; }; };
                result = lc.evaluateLicenseUsage ctx l;
              in
              if !result.allowed then true
              else throw "FAIL: ${ln}: obligation '${oblName}' triggered but commitment=false didn't block"
          )
          oblKeys;

      results = map check licenseNames;
    in
    assertTrue "commitments block for all 2600+ when can't fulfill"
      (builtins.all (x: x) results);

  commitmentsAllowWhenCanFulfill =
    let
      check = ln: ctx:
        let
          l = licenses.${ln};
          # All commitments = true means obligations never block
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
        # Should only be blocked by restrictions or allowed-use, never by commitments
        if !result.allowed then
          builtins.all (c: c.restriction != "commitment") result.conflicts
        else true;

      results = builtins.concatMap
        (ln: map (ctx: check ln ctx) allUsageContexts)
        licenseNames;
    in
    assertTrue "commitments=true never blocks for all 2600+ × 16"
      (builtins.all (x: x) results);

  # ── Assurances: 2600+ ────────────────────────────────────────
  #
  # If a license disclaims X and user requires X → blocked
  # If no assurances required → never blocked by disclaimers

  noAssurancesNeverBlocks =
    let
      check = ln: ctx:
        let
          result = lc.evaluateLicenseUsage ctx licenses.${ln};
        in
        # With no assurances, no assurance conflicts
        builtins.all (c: c.restriction != "assurance") (result.conflicts or [ ]);

      results = builtins.concatMap
        (ln: map (ctx: check ln ctx) allUsageContexts)
        licenseNames;
    in
    assertTrue "no assurances = no assurance blocks for all 2600+ × 16"
      (builtins.all (x: x) results);

  assurancesBlockDisclaimers =
    let
      assuranceKeys = {
        patent-grant = "patent-use";
        liability-coverage = "liability";
        warranty = "warranty";
      };

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
        # No disclaimer → assurance should not block
          let assuranceConflicts = builtins.filter (c: c.restriction == "assurance") result.conflicts;
          in if assuranceConflicts == [ ] then true
          else throw "FAIL: ${ln}: no '${disclaimerKey}' disclaimer but assurance '${assuranceKey}' blocked";

      results = builtins.concatMap
        (ln: map (k: check ln k) (builtins.attrNames assuranceKeys))
        licenseNames;
    in
    assertTrue "assurances correctly block/allow for all 2600+ × 3 assurance keys"
      (builtins.all (x: x) results);

  # ── Coverage ────────────────────────────────────────────────────

  usageContextCount = assertEq "16 contexts (2^4)" (builtins.length allUsageContexts) 16;
  oarsFromSpec = assertEq "OARS from spec" types.oarsCategories oarsSpec.categories;
  licenseCount = assertTrue "2600+ licenses" (builtins.length licenseNames >= 2600);
}
