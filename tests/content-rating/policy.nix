# Content policy properties: hierarchy, stability

{ lib, oarsSpec }:

let
  cr = import ../../lib/content-rating/rating.nix { inherit lib oarsSpec; };
  types = import ../../lib/content-rating/types.nix { inherit lib oarsSpec; };

  assertTrue = name: value:
    if value then true
    else throw "FAIL: ${name}";

  intensities = [ "none" "mild" "moderate" "intense" ];
in
{
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
}
