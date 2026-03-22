# Types derived from the OARS 1.1 specification
# Categories and severity values are parsed from the upstream RNC schema,
# not hand-maintained. Update the `oars` flake input to pick up spec changes.

{ lib, oarsSpec }:

let
  inherit (lib) types;
in
{
  # OARS version being used
  oarsVersion = oarsSpec.version;

  # OARS 1.1 severity levels (from spec: "unknown" | "none" | "mild" | "moderate" | "intense")
  severityType = types.enum oarsSpec.severityValues;

  # Severity type for policy maximums (unknown not valid in policies —
  # a policy must state a concrete maximum, not "we don't know")
  policySeverityType = types.enum
    (builtins.filter (v: v != "unknown") oarsSpec.severityValues);

  # Content rating preset type
  contentRatingPresetType = types.enum [
    "everyone"
    "everyone-10"
    "teen"
    "mature"
    "adults-only"
  ];

  # Content policy preset type
  contentPolicyPresetType = types.enum [
    "child"
    "teen"
    "unrestricted"
  ];

  # Usage context type
  usageType = types.enum [
    "personal"
    "commercial"
    "educational"
    "government"
  ];

  # License enforcement level
  enforcementType = types.enum [ "warn" "enforce" ];

  # OARS 1.1 attribute IDs (derived from upstream RNC schema)
  oarsCategories = oarsSpec.categories;

  # Content policy preset definitions
  # Values must only use categories from oarsSpec.categories
  policyPresets =
    let
      # Generate a preset by mapping each category to a severity
      mkPreset = defaults: allowUnrated:
        (builtins.listToAttrs
          (map (cat: { name = cat; value = defaults.${cat} or "none"; })
            oarsSpec.categories))
        // { inherit allowUnrated; };
    in
    {
      child = mkPreset
        {
          violence-cartoon = "mild";
          language-humor = "mild";
        }
        false;

      teen = mkPreset
        {
          violence-cartoon = "intense";
          violence-fantasy = "moderate";
          violence-realistic = "mild";
          violence-slavery = "mild";
          drugs-alcohol = "mild";
          drugs-tobacco = "mild";
          sex-nudity = "mild";
          sex-themes = "mild";
          language-profanity = "moderate";
          language-humor = "moderate";
          social-chat = "moderate";
          social-info = "mild";
          social-audio = "moderate";
          social-contacts = "mild";
          money-purchasing = "mild";
        }
        false;

      unrestricted =
        (builtins.listToAttrs
          (map (cat: { name = cat; value = "intense"; })
            oarsSpec.categories))
        // { allowUnrated = true; };
    };
}
