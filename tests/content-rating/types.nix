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
  presetChildExists = assertHasAttr "child preset exists" "child" types.policyPresets;
  presetTeenExists = assertHasAttr "teen preset exists" "teen" types.policyPresets;
  presetUnrestrictedExists = assertHasAttr "unrestricted preset exists" "unrestricted" types.policyPresets;

  # Child preset is restrictive
  childNoViolence = assertEq
    "child preset blocks realistic violence"
    types.policyPresets.child.violence-realistic
    "none";

  childNoGambling = assertEq
    "child preset blocks gambling"
    types.policyPresets.child.money-gambling
    "none";

  childNoChat = assertEq
    "child preset blocks chat"
    types.policyPresets.child.social-chat
    "none";

  childAllowsMildCartoon = assertEq
    "child preset allows mild cartoon violence"
    types.policyPresets.child.violence-cartoon
    "mild";

  childBlocksUnrated = assertEq
    "child preset blocks unrated"
    types.policyPresets.child.allowUnrated
    false;

  # Teen preset is moderate
  teenAllowsModerateFantasy = assertEq
    "teen preset allows moderate fantasy violence"
    types.policyPresets.teen.violence-fantasy
    "moderate";

  teenAllowsMildRealistic = assertEq
    "teen preset allows mild realistic violence"
    types.policyPresets.teen.violence-realistic
    "mild";

  teenNoGambling = assertEq
    "teen preset blocks gambling"
    types.policyPresets.teen.money-gambling
    "none";

  teenBlocksUnrated = assertEq
    "teen preset blocks unrated"
    types.policyPresets.teen.allowUnrated
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
    "child preset covers all OARS categories"
    (builtins.all (cat: types.policyPresets.child ? ${cat}) types.oarsCategories);

  teenCoversAll = assertTrue
    "teen preset covers all OARS categories"
    (builtins.all (cat: types.policyPresets.teen ? ${cat}) types.oarsCategories);

  unrestrictedCoversAll = assertTrue
    "unrestricted preset covers all OARS categories"
    (builtins.all (cat: types.policyPresets.unrestricted ? ${cat}) types.oarsCategories);
}
