# Tests for lib/content-rating.nix
# Run via: nix eval .#checks.<system>.lib-content-rating

{ lib, oarsSpec }:

let
  cr = import ../lib/content-rating/rating.nix { inherit lib oarsSpec; };
  types = import ../lib/content-rating/types.nix { inherit lib oarsSpec; };

  # Test helpers
  assertEq = name: actual: expected:
    if actual == expected then true
    else throw "FAIL: ${name}: expected ${builtins.toJSON expected}, got ${builtins.toJSON actual}";

  assertTrue = name: value:
    if value then true
    else throw "FAIL: ${name}: expected true";

  assertFalse = name: value:
    if !value then true
    else throw "FAIL: ${name}: expected false";

in
{
  # ── SEVERITY LEVELS ────────────────────────────────────────────

  # Same level
  noneAllowedByNone = assertTrue "none <= none" (cr.severityAllowed "none" "none");
  mildAllowedByMild = assertTrue "mild <= mild" (cr.severityAllowed "mild" "mild");
  moderateAllowedByModerate = assertTrue "moderate <= moderate" (cr.severityAllowed "moderate" "moderate");
  intenseAllowedByIntense = assertTrue "intense <= intense" (cr.severityAllowed "intense" "intense");

  # Lower <= higher
  noneAllowedByMild = assertTrue "none <= mild" (cr.severityAllowed "none" "mild");
  noneAllowedByModerate = assertTrue "none <= moderate" (cr.severityAllowed "none" "moderate");
  noneAllowedByIntense = assertTrue "none <= intense" (cr.severityAllowed "none" "intense");
  mildAllowedByModerate = assertTrue "mild <= moderate" (cr.severityAllowed "mild" "moderate");
  mildAllowedByIntense = assertTrue "mild <= intense" (cr.severityAllowed "mild" "intense");
  moderateAllowedByIntense = assertTrue "moderate <= intense" (cr.severityAllowed "moderate" "intense");

  # Higher > lower (should fail)
  mildNotAllowedByNone = assertFalse "mild > none" (cr.severityAllowed "mild" "none");
  moderateNotAllowedByNone = assertFalse "moderate > none" (cr.severityAllowed "moderate" "none");
  intenseNotAllowedByNone = assertFalse "intense > none" (cr.severityAllowed "intense" "none");
  moderateNotAllowedByMild = assertFalse "moderate > mild" (cr.severityAllowed "moderate" "mild");
  intenseNotAllowedByMild = assertFalse "intense > mild" (cr.severityAllowed "intense" "mild");
  intenseNotAllowedByModerate = assertFalse "intense > moderate" (cr.severityAllowed "intense" "moderate");

  # ── SEVERITY LEVEL VALUES ─────────────────────────────────────

  orderNone = assertEq "none = 0" cr.severityLevel.none 0;
  orderMild = assertEq "mild = 1" cr.severityLevel.mild 1;
  orderModerate = assertEq "moderate = 2" cr.severityLevel.moderate 2;
  orderIntense = assertEq "intense = 3" cr.severityLevel.intense 3;

  # Strict ordering
  orderNoneLtMild = assertTrue "none < mild" (cr.severityLevel.none < cr.severityLevel.mild);
  orderMildLtModerate = assertTrue "mild < moderate" (cr.severityLevel.mild < cr.severityLevel.moderate);
  orderModerateLtIntense = assertTrue "moderate < intense" (cr.severityLevel.moderate < cr.severityLevel.intense);

  # ── CONTENT POLICY RESOLUTION ─────────────────────────────────

  # String preset resolution
  resolveChildPreset = assertEq
    "resolve 'child' string"
    (cr.resolveContentPolicy "child")
    types.policyPresets.child;

  resolveTeen = assertEq
    "resolve 'teen' string"
    (cr.resolveContentPolicy "teen")
    types.policyPresets.teen;

  resolveUnrestricted = assertEq
    "resolve 'unrestricted' string"
    (cr.resolveContentPolicy "unrestricted")
    types.policyPresets.unrestricted;

  # Attrset with preset + overrides
  resolvePresetWithOverride = assertEq
    "resolve preset with override"
    (cr.resolveContentPolicy {
      preset = "child";
      violence-cartoon = "moderate";
    }).violence-cartoon
    "moderate";

  resolvePresetKeepsOthers = assertEq
    "resolve preset keeps non-overridden values"
    (cr.resolveContentPolicy {
      preset = "child";
      violence-cartoon = "moderate";
    }).violence-realistic
    "none";

  # Attrset without preset defaults to unrestricted
  resolveNoPreset = assertEq
    "resolve without preset defaults to unrestricted base"
    (cr.resolveContentPolicy {
      violence-cartoon = "mild";
    }).violence-realistic
    "intense";

  resolveNoPresetOverride = assertEq
    "resolve without preset applies override"
    (cr.resolveContentPolicy {
      violence-cartoon = "mild";
    }).violence-cartoon
    "mild";

  # ── CONTENT RATING EVALUATION ─────────────────────────────────

  # Package within policy
  unrestrictedAllowsEverything =
    let
      result = cr.evaluateContentRating "unrestricted" {
        violence-cartoon = "intense";
        money-gambling = "intense";
      };
    in
    assertTrue "unrestricted allows everything" result.allowed;

  checkAllowedChild =
    let
      result = cr.evaluateContentRating "child" {
        violence-cartoon = "mild";
        language-humor = "mild";
      };
    in
    assertTrue "child allows mild cartoon + mild humor" result.allowed;

  checkAllowedExactMatch =
    let
      result = cr.evaluateContentRating "child" {
        violence-cartoon = "mild";
      };
    in
    assertTrue "exact match on boundary is allowed" result.allowed;

  checkAllowedNone =
    let
      result = cr.evaluateContentRating "child" {
        violence-cartoon = "none";
        violence-realistic = "none";
        money-gambling = "none";
      };
    in
    assertTrue "all none is always allowed" result.allowed;

  # Package exceeds policy
  checkBlockedViolence =
    let
      result = cr.evaluateContentRating "child" {
        violence-realistic = "moderate";
      };
    in
    assertFalse "child blocks moderate realistic violence" result.allowed;

  checkBlockedGambling =
    let
      result = cr.evaluateContentRating "child" {
        money-gambling = "mild";
      };
    in
    assertFalse "child blocks any gambling" result.allowed;

  checkBlockedChat =
    let
      result = cr.evaluateContentRating "teen" {
        social-chat = "intense";
      };
    in
    assertFalse "teen blocks intense chat" result.allowed;

  # Violations list
  violationsCount =
    let
      result = cr.evaluateContentRating "child" {
        violence-realistic = "intense";
        money-gambling = "moderate";
        violence-cartoon = "mild";
      };
    in
    assertEq "two violations" (builtins.length result.violations) 2;

  violationsContainCategory =
    let
      result = cr.evaluateContentRating "child" {
        violence-realistic = "intense";
      };
      v = builtins.head result.violations;
    in
    assertEq "violation category" v.category "violence-realistic";

  violationsContainRating =
    let
      result = cr.evaluateContentRating "child" {
        violence-realistic = "intense";
      };
      v = builtins.head result.violations;
    in
    assertEq "violation rating" v.rating "intense";

  violationsContainMaximum =
    let
      result = cr.evaluateContentRating "child" {
        violence-realistic = "intense";
      };
      v = builtins.head result.violations;
    in
    assertEq "violation maximum" v.maximum "none";

  # Empty content rating
  checkEmptyRating =
    let result = cr.evaluateContentRating "child" { };
    in assertTrue "empty content rating is allowed" result.allowed;

  # Unknown categories in rating are ignored
  checkUnknownCategory =
    let result = cr.evaluateContentRating "child" { unknown-category = "intense"; };
    in assertTrue "unknown categories are ignored" result.allowed;

  # With preset + override policy
  checkCustomPolicy =
    let
      result = cr.evaluateContentRating
        { preset = "child"; violence-cartoon = "intense"; }
        { violence-cartoon = "intense"; };
    in
    assertTrue "custom policy with override allows intense cartoon" result.allowed;

  checkCustomPolicyStillBlocks =
    let
      result = cr.evaluateContentRating
        { preset = "child"; violence-cartoon = "intense"; }
        { violence-realistic = "moderate"; };
    in
    assertFalse "custom policy still blocks non-overridden categories" result.allowed;

  # ── UNRATED CONTENT POLICY ────────────────────────────────────

  unrestrictedAllowsUnrated = assertTrue
    "unrestricted allows unrated"
    (cr.allowsUnratedContent "unrestricted");

  unratedBlockedChild = assertFalse
    "child blocks unrated"
    (cr.allowsUnratedContent "child");

  unratedBlockedTeen = assertFalse
    "teen blocks unrated"
    (cr.allowsUnratedContent "teen");

  unratedCustomAllow = assertTrue
    "custom policy can allow unrated"
    (cr.allowsUnratedContent { allowUnrated = true; });

  unratedCustomBlock = assertFalse
    "custom policy can block unrated"
    (cr.allowsUnratedContent { allowUnrated = false; });

  # ── DOMAIN MODEL GUARANTEES ───────────────────────────────────

  # For every preset, every OARS category has a valid intensity
  allPresetsAllCategoriesValid =
    let
      validIntensities = [ "none" "mild" "moderate" "intense" ];
      presetNames = builtins.attrNames types.policyPresets;
      check = presetName:
        builtins.all
          (cat:
            builtins.elem types.policyPresets.${presetName}.${cat} validIntensities
          )
          types.oarsCategories;
    in
    assertTrue
      "all presets have valid intensities for all categories"
      (builtins.all check presetNames);

  # severityAllowed is reflexive: x <= x for all levels
  severityLevelIsComparableToItself =
    let levels = [ "none" "mild" "moderate" "intense" ];
    in assertTrue
      "severityAllowed is reflexive"
      (builtins.all (l: cr.severityAllowed l l) levels);

  # severityAllowed is transitive: if a <= b and b <= c then a <= c
  severityOrderIsConsistent =
    let
      levels = [ "none" "mild" "moderate" "intense" ];
      triples = builtins.concatMap
        (a: builtins.concatMap
          (b: map (c: { inherit a b c; }) levels)
          levels)
        levels;
      check = { a, b, c }:
        if cr.severityAllowed a b && cr.severityAllowed b c then
          cr.severityAllowed a c
        else
          true;
    in
    assertTrue
      "severityAllowed is transitive"
      (builtins.all check triples);

  # severityAllowed is antisymmetric: if a <= b and b <= a then a == b
  antisymmetric =
    let
      levels = [ "none" "mild" "moderate" "intense" ];
      pairs = builtins.concatMap
        (a: map (b: { inherit a b; }) levels)
        levels;
      check = { a, b }:
        if cr.severityAllowed a b && cr.severityAllowed b a then
          a == b
        else
          true;
    in
    assertTrue
      "severityAllowed is antisymmetric"
      (builtins.all check pairs);

  # severityAllowed is total: for all a b, either a <= b or b <= a
  total =
    let
      levels = [ "none" "mild" "moderate" "intense" ];
      pairs = builtins.concatMap
        (a: map (b: { inherit a b; }) levels)
        levels;
      check = { a, b }:
        cr.severityAllowed a b || cr.severityAllowed b a;
    in
    assertTrue
      "severityAllowed is a total order"
      (builtins.all check pairs);

  # For every preset, a package rated at the preset's exact levels is allowed
  presetsAllowExactMatch =
    let
      presetNames = builtins.attrNames types.policyPresets;
      check = presetName:
        let
          preset = types.policyPresets.${presetName};
          rating = builtins.listToAttrs (map
            (cat: { name = cat; value = preset.${cat}; })
            types.oarsCategories);
          result = cr.evaluateContentRating presetName rating;
        in
        result.allowed;
    in
    assertTrue
      "all presets allow packages matching their exact levels"
      (builtins.all check presetNames);

  # Child is strictly more restrictive than teen for all categories
  childMoreRestrictiveThanTeen =
    assertTrue
      "child is at most as permissive as teen for all categories"
      (builtins.all
        (cat: cr.severityAllowed
          types.policyPresets.child.${cat}
          types.policyPresets.teen.${cat})
        types.oarsCategories);

  # Teen is strictly more restrictive than unrestricted for all categories
  teenMoreRestrictiveThanUnrestricted =
    assertTrue
      "teen is at most as permissive as unrestricted for all categories"
      (builtins.all
        (cat: cr.severityAllowed
          types.policyPresets.teen.${cat}
          types.policyPresets.unrestricted.${cat})
        types.oarsCategories);
}
