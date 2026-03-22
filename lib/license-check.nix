# License compliance evaluation
#
# Evaluates whether a usage context is permitted by a license's
# restrictions, and identifies triggered obligations.
#
# Usage fields match SALT restriction keys exactly.

_:

let
  # Evaluate a license against a usage context
  # Usage is a flat attrset of booleans matching SALT restriction keys:
  #   { commercial-use = true; distribution = false; modifications = true; saas = false; }
  evaluateLicenseUsage = usage: license:
    let
      restrictions = license.restrictions or { };
      obligations = license.obligations or { };

      # For each SALT restriction key, check if usage conflicts
      restrictionKeys = builtins.attrNames restrictions;
      conflicts = builtins.filter (c: c != null) (map
        (key:
          let
            isRestricted = restrictions.${key} or false;
            isUsed = usage.${key} or false;
          in
          if isRestricted && isUsed then
            { restriction = key; reason = "License prohibits ${key}"; }
          else null
        )
        restrictionKeys);

      # Check which obligations are triggered
      obligationChecks = builtins.concatMap
        (name:
          let
            triggers = obligations.${name} or [ ];
            matchedTriggers = builtins.filter
              (trigger:
                trigger == "any"
                || (usage.${trigger} or false)
              )
              triggers;
          in
          if matchedTriggers != [ ] then
            [{ obligation = name; triggers = matchedTriggers; }]
          else
            [ ]
        )
        (builtins.attrNames obligations);

    in
    {
      allowed = conflicts == [ ];
      inherit conflicts;
      obligations = obligationChecks;
    };

  # Evaluate source availability
  evaluateSourceAvailability = allowClosedSource: license:
    let
      isFree = license.free or true;
    in
    {
      allowed = isFree || allowClosedSource;
      reason =
        if isFree then null
        else if allowClosedSource then null
        else "Package is closed-source but allowClosedSource is false";
    };

  # Full compliance evaluation
  evaluateCompliance =
    { allowClosedSource ? true
    , usage ? { }
    , license
    }:
    let
      sourceCheck = evaluateSourceAvailability allowClosedSource license;
      licenseCheck = evaluateLicenseUsage usage license;
    in
    {
      allowed = sourceCheck.allowed && licenseCheck.allowed;
      sourceAllowed = sourceCheck.allowed;
      sourceReason = sourceCheck.reason;
      inherit (licenseCheck) conflicts obligations;
    };

in
{
  inherit evaluateLicenseUsage evaluateSourceAvailability evaluateCompliance;
}
