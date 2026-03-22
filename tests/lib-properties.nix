# Domain model guarantees — uses SALT terminology

{ lib, oarsSpec, saltLicenses }:

let
  cr = import ../lib/content-rating.nix { inherit lib oarsSpec; };
  types = import ../lib/types.nix { inherit lib oarsSpec; };
  licenses = import ../lib/licenses.nix { inherit lib saltLicenses; };
  lc = import ../lib/license-check.nix { inherit lib; };

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

  allUsageContexts = builtins.concatMap
    (t: map (flags: { type = t; } // flags) (boolProduct [ "distribution" "saas" "military" ]))
    [ "personal" "commercial" "educational" "government" ];

  licenseNames = builtins.filter
    (n: !(builtins.elem n [ "_meta" "allRestrictions" "allObligations" "allGrants" "allDisclaimers" ]))
    (builtins.attrNames licenses);

in
{
  # ── Severity ────────────────────────────────────────────────────

  severityReflexive = assertTrue "severity reflexive"
    (builtins.all (a: cr.severityAllowed a a) intensities);

  severityAntisymmetric = assertTrue "severity antisymmetric"
    (builtins.all ({ a, b }: if cr.severityAllowed a b && cr.severityAllowed b a then a == b else true) (pairs intensities));

  severityTransitive = assertTrue "severity transitive"
    (builtins.all ({ a, b, c }: if cr.severityAllowed a b && cr.severityAllowed b c then cr.severityAllowed a c else true) (triples intensities));

  severityTotal = assertTrue "severity total"
    (builtins.all ({ a, b }: cr.severityAllowed a b || cr.severityAllowed b a) (pairs intensities));

  # ── Content policy hierarchy ────────────────────────────────────

  childMoreRestrictiveThanTeen = assertTrue "child < teen"
    (builtins.all (cat: cr.severityAllowed types.policyPresets.child.${cat} types.policyPresets.teen.${cat}) types.oarsCategories);

  teenMoreRestrictiveThanUnrestricted = assertTrue "teen < unrestricted"
    (builtins.all (cat: cr.severityAllowed types.policyPresets.teen.${cat} types.policyPresets.unrestricted.${cat}) types.oarsCategories);

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

  moreRestrictionsNeverGrantAccess =
    let
      bl = builtins.filter (n: !(licenses.${n} ? allowedUsageTypes)) licenseNames;
      sub = r1: r2: builtins.all (key: if r1.${key} or false then r2.${key} or false else true) licenses.allRestrictions;
    in
    assertTrue "more restrictions never grant access"
      (builtins.all
        (l1: builtins.all
          (l2:
            if sub licenses.${l1}.restrictions licenses.${l2}.restrictions then
              builtins.all
                (ctx:
                  let r1 = lc.evaluateLicenseUsage ctx licenses.${l1}; r2 = lc.evaluateLicenseUsage ctx licenses.${l2};
                  in if r2.allowed then r1.allowed else true
                )
                allUsageContexts
            else true
          )
          bl)
        bl);

  addingCapabilitiesNeverRemovesConflicts =
    let
      base = { type = "personal"; distribution = false; saas = false; military = false; };
    in
    assertTrue "adding capabilities never removes conflicts"
      (builtins.all
        (ln:
          let
            l = licenses.${ln};
            bR = lc.evaluateLicenseUsage base l;
            dR = lc.evaluateLicenseUsage (base // { distribution = true; }) l;
            sR = lc.evaluateLicenseUsage (base // { saas = true; }) l;
            mR = lc.evaluateLicenseUsage (base // { military = true; }) l;
          in
          (if dR.allowed then bR.allowed else true)
          && (if sR.allowed then bR.allowed else true)
          && (if mR.allowed then bR.allowed else true)
        )
        licenseNames);

  commercialAtLeastAsRestrictedAsPersonal = assertTrue "commercial >= personal"
    (builtins.all
      (ln:
        let
          l = licenses.${ln};
          pR = lc.evaluateLicenseUsage { type = "personal"; } l;
          cR = lc.evaluateLicenseUsage { type = "commercial"; } l;
        in
        if cR.allowed then pR.allowed else true)
      licenseNames);

  complianceIsBothSourceAndLicense = assertTrue "compliance = source AND license"
    (builtins.all
      (ln: builtins.all
        (ctx: builtins.all
          (acs:
            let
              r = lc.evaluateCompliance { allowClosedSource = acs; usage = ctx; license = licenses.${ln}; };
              sOk = (lc.evaluateSourceAvailability acs licenses.${ln}).allowed;
              lOk = (lc.evaluateLicenseUsage ctx licenses.${ln}).allowed;
            in
            r.allowed == (sOk && lOk)
          ) [ true false ])
        allUsageContexts)
      licenseNames);

  noRestrictionsUniversallyAllowed = assertTrue "no restrictions = universally allowed"
    (builtins.all
      (ln:
        let l = licenses.${ln};
        in if l.restrictions == { } && !(l ? allowedUsageTypes) then
          builtins.all (ctx: (lc.evaluateLicenseUsage ctx l).allowed) allUsageContexts
        else true)
      licenseNames);

  # ── Coverage ────────────────────────────────────────────────────

  usageContextCount = assertEq "32 contexts" (builtins.length allUsageContexts) 32;
  oarsFromSpec = assertEq "OARS from spec" types.oarsCategories oarsSpec.categories;
  licenseCount = assertTrue "2600+ licenses" (builtins.length licenseNames >= 2600);
}
