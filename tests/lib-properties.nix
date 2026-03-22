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

  allUsageContexts =
    boolProduct [ "commercial-use" "distribution" "modifications" "saas" ];

  licenseNames = builtins.filter
    (n: !(builtins.elem n [ "_meta" "allRestrictions" "allObligations" "allGrants" "allDisclaimers" ]))
    (builtins.attrNames licenses);

in
{
  severityReflexive = assertTrue "severity reflexive"
    (builtins.all (a: cr.severityAllowed a a) intensities);

  severityTransitive = assertTrue "severity transitive"
    (builtins.all ({ a, b, c }: if cr.severityAllowed a b && cr.severityAllowed b c then cr.severityAllowed a c else true) (triples intensities));

  severityTotal = assertTrue "severity total"
    (builtins.all ({ a, b }: cr.severityAllowed a b || cr.severityAllowed b a) (pairs intensities));

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
        in if l.restrictions == { } then
          builtins.all (ctx: (lc.evaluateLicenseUsage ctx l).allowed) allUsageContexts
        else true)
      licenseNames);

  usageContextCount = assertEq "16 contexts (2^4)" (builtins.length allUsageContexts) 16;
  oarsFromSpec = assertEq "OARS from spec" types.oarsCategories oarsSpec.categories;
  licenseCount = assertTrue "2600+ licenses" (builtins.length licenseNames >= 2600);
}
