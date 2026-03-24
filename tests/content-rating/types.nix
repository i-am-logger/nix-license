# Tests for lib/types.nix
# Run via: nix eval .#checks.<system>.lib-types

{ lib, oarsSpec }:

let
  types = import ../../lib/content-rating/types.nix { inherit lib oarsSpec; };

  # Test helper: assert with message
  assertEq = name: actual: expected:
    if actual == expected then true
    else throw "FAIL: ${name}: expected ${builtins.toJSON expected}, got ${builtins.toJSON actual}";

  assertTrue = name: value:
    if value then true
    else throw "FAIL: ${name}: expected true";

  assertHasAttr = name: attrName: attrs:
    if attrs ? ${attrName} then true
    else throw "FAIL: ${name}: missing attribute '${attrName}'";

in
{
  # OARS categories
  oarsCategoriesNotEmpty = assertTrue
    "oarsCategories is not empty"
    (builtins.length types.oarsCategories > 0);

  oarsCategoriesExactCount = assertEq
    "OARS 1.1 has exactly 22 categories"
    (builtins.length types.oarsCategories) 22;

  oarsCategoriesContainsViolence = assertTrue
    "oarsCategories contains violence-cartoon"
    (builtins.elem "violence-cartoon" types.oarsCategories);

  oarsCategoriesContainsSocial = assertTrue
    "oarsCategories contains social-chat"
    (builtins.elem "social-chat" types.oarsCategories);

  oarsCategoriesContainsMoney = assertTrue
    "oarsCategories contains money-gambling"
    (builtins.elem "money-gambling" types.oarsCategories);

  oarsCategoriesContainsDrugs = assertTrue
    "oarsCategories contains drugs-alcohol"
    (builtins.elem "drugs-alcohol" types.oarsCategories);

  oarsCategoriesContainsSex = assertTrue
    "oarsCategories contains sex-nudity"
    (builtins.elem "sex-nudity" types.oarsCategories);

  oarsCategoriesContainsLanguage = assertTrue
    "oarsCategories contains language-profanity"
    (builtins.elem "language-profanity" types.oarsCategories);

  oarsCategoriesMatchSpec = assertEq
    "oarsCategories matches oarsSpec.categories"
    types.oarsCategories
    oarsSpec.categories;

  # Policy presets exist
  presetRestrictedExists = assertHasAttr "restricted preset exists" "restricted" types.policyPresets;
  presetModerateExists = assertHasAttr "moderate preset exists" "moderate" types.policyPresets;
  presetUnrestrictedExists = assertHasAttr "unrestricted preset exists" "unrestricted" types.policyPresets;

  # Child preset is restrictive
  restrictedNoViolence = assertEq
    "restricted preset blocks realistic violence"
    types.policyPresets.restricted.violence-realistic
    "none";

  restrictedNoGambling = assertEq
    "restricted preset blocks gambling"
    types.policyPresets.restricted.money-gambling
    "none";

  restrictedNoChat = assertEq
    "restricted preset blocks chat"
    types.policyPresets.restricted.social-chat
    "none";

  restrictedAllowsMildCartoon = assertEq
    "restricted preset allows mild cartoon violence"
    types.policyPresets.restricted.violence-cartoon
    "mild";

  childBlocksUnrated = assertEq
    "restricted preset blocks unrated"
    types.policyPresets.restricted.allowUnrated
    false;

  # Teen preset is moderate
  moderateAllowsModerateFantasy = assertEq
    "moderate preset allows moderate fantasy violence"
    types.policyPresets.moderate.violence-fantasy
    "moderate";

  moderateAllowsMildRealistic = assertEq
    "moderate preset allows mild realistic violence"
    types.policyPresets.moderate.violence-realistic
    "mild";

  moderateNoGambling = assertEq
    "moderate preset blocks gambling"
    types.policyPresets.moderate.money-gambling
    "none";

  teenBlocksUnrated = assertEq
    "moderate preset blocks unrated"
    types.policyPresets.moderate.allowUnrated
    false;

  # Unrestricted preset allows everything
  unrestrictedAllowsAll = assertEq
    "unrestricted preset allows intense violence"
    types.policyPresets.unrestricted.violence-realistic
    "intense";

  unrestrictedAllowsGambling = assertEq
    "unrestricted preset allows gambling"
    types.policyPresets.unrestricted.money-gambling
    "intense";

  unrestrictedAllowsUnrated = assertEq
    "unrestricted allows unrated"
    types.policyPresets.unrestricted.allowUnrated
    true;

  # Every preset covers all OARS categories
  childCoversAll = assertTrue
    "restricted preset covers all OARS categories"
    (builtins.all (cat: types.policyPresets.restricted ? ${cat}) types.oarsCategories);

  teenCoversAll = assertTrue
    "moderate preset covers all OARS categories"
    (builtins.all (cat: types.policyPresets.moderate ? ${cat}) types.oarsCategories);

  unrestrictedCoversAll = assertTrue
    "unrestricted preset covers all OARS categories"
    (builtins.all (cat: types.policyPresets.unrestricted ? ${cat}) types.oarsCategories);
}
