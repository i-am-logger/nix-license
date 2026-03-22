# License compliance evaluation
#
# Two independent checks:
# 1. allowed-use: if the license specifies who can use it,
#    the user's type must be in the list
# 2. restrictions: if the license restricts an activity,
#    and the user does that activity, it's a conflict

_:

let
  evaluateLicenseUsage = usage: license:
    let
      restrictions = license.restrictions or { };
      obligations = license.obligations or { };
      allowedUse = license.allowed-use or license.allowedUsageTypes or null;
      userType = usage.type or null;

      # Check 1: allowed-use (allowlist)
      typeConflict =
        if allowedUse != null && userType != null then
          !(builtins.elem userType allowedUse)
        else
          false;

      typeConflicts =
        if typeConflict then
          [{ restriction = "allowed-use"; reason = "License only allows: ${builtins.concatStringsSep ", " allowedUse}"; }]
        else
          [ ];

      # Check 2: restrictions (blocklist)
      restrictionKeys = builtins.attrNames restrictions;
      restrictionConflicts = builtins.filter (c: c != null) (map
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

      allConflicts = typeConflicts ++ restrictionConflicts;

      # Check obligations
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
            [{ obligation = name; inherit triggers; }]
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
