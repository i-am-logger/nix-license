# License compliance evaluation
#
# Evaluates whether a usage context is permitted by a license's
# restrictions, and identifies triggered obligations.
#
# Uses SALT terminology throughout.

_:

let
  # Evaluate a license against a usage context
  evaluateLicenseUsage = usage: license:
    let
      restrictions = license.restrictions or { };
      obligations = license.obligations or { };
      allowedTypes = license.allowedUsageTypes or null;

      isCommercial = (usage.type or "personal") == "commercial";
      isMilitary = usage.military or false;
      isGovernment = (usage.type or "personal") == "government";
      isDistributing = usage.distribution or usage.redistribution or false;
      isSaas = usage.saas or false;

      restrictionChecks = [
        {
          check = (restrictions.commercial-use or false) && isCommercial;
          restriction = "commercial-use";
          reason = "License prohibits commercial use";
        }
        {
          check = (restrictions.military or false) && isMilitary;
          restriction = "military";
          reason = "License prohibits military/defense use";
        }
        {
          check = (restrictions.government or false) && isGovernment;
          restriction = "government";
          reason = "License prohibits government use";
        }
        {
          check = (restrictions.distribution or false) && isDistributing;
          restriction = "distribution";
          reason = "License prohibits redistribution";
        }
        {
          check = (restrictions.saas or false) && isSaas;
          restriction = "saas";
          reason = "License prohibits running as a service";
        }
      ];

      typeRestricted =
        if allowedTypes != null then
          !(builtins.elem (usage.type or "personal") allowedTypes)
        else
          false;

      conflicts = builtins.filter (c: c.check) restrictionChecks;
      conflictResults = map (c: { inherit (c) restriction reason; }) conflicts;

      allConflicts =
        if typeRestricted then
          conflictResults ++ [{
            restriction = "usageType";
            reason = "License only permits: ${builtins.concatStringsSep ", " allowedTypes}";
          }]
        else
          conflictResults;

      # Check which obligations are triggered
      obligationChecks = builtins.concatMap
        (name:
          let
            triggers = obligations.${name} or [ ];
            matchedTriggers = builtins.filter
              (trigger:
                trigger == "any"
                || (trigger == "distribution" && isDistributing)
                || (trigger == "saas" && isSaas)
                || (trigger == "commercial" && isCommercial)
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
      allowed = allConflicts == [ ];
      conflicts = allConflicts;
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
    , usage ? { type = "personal"; }
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
