# Content rating evaluation
#
# Evaluates package content ratings against user content policies.

{ lib, oarsSpec }:

let
  licenseTypes = import ./types.nix { inherit lib oarsSpec; };

  # Maps severity names to their rank for comparison
  severityLevel = {
    "none" = 0;
    "mild" = 1;
    "moderate" = 2;
    "intense" = 3;
  };

  # Is this severity level allowed by the policy maximum?
  severityAllowed = rating: maximum:
    severityLevel.${rating} <= severityLevel.${maximum};

  # Resolve a content policy (preset string or attrset) into a full policy attrset
  resolveContentPolicy = policy:
    if builtins.isString policy then
      licenseTypes.policyPresets.${policy}
    else
      let
        base =
          if policy ? preset then
            licenseTypes.policyPresets.${policy.preset}
          else
            licenseTypes.policyPresets.unrestricted;
      in
      base // (builtins.removeAttrs policy [ "preset" ]);

  # Evaluate a package's content rating against a content policy
  # Returns { allowed = bool; violations = [ { category, rating, maximum } ]; }
  evaluateContentRating = policy: contentRating:
    let
      resolved = resolveContentPolicy policy;
      categories = builtins.filter
        (cat: contentRating ? ${cat} && resolved ? ${cat})
        licenseTypes.oarsCategories;
      violations = builtins.filter
        (v: v != null)
        (map
          (cat:
            let
              rating = contentRating.${cat};
              maximum = resolved.${cat};
            in
            if severityAllowed rating maximum then
              null
            else
              { category = cat; inherit rating maximum; }
          )
          categories);
    in
    {
      allowed = violations == [ ];
      inherit violations;
    };

  # Does this content policy allow unrated packages?
  allowsUnratedContent = policy:
    let resolved = resolveContentPolicy policy;
    in resolved.allowUnrated or true;

in
{
  inherit
    severityAllowed
    severityLevel
    resolveContentPolicy
    evaluateContentRating
    allowsUnratedContent
    ;
}
