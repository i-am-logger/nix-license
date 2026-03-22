# License compliance evaluation
#
# Two checks:
# 1. allowed-use: if license has an allowlist, user's type must be in it
# 2. restrictions: if license restricts an activity the user does, it's a conflict

_:

let
  evaluateLicenseUsage = usage: license:
    let
      restrictions = license.restrictions or { };
      obligations = license.obligations or { };
      allowedUse = license.allowed-use or license.allowedUsageTypes or null;
      userType = usage.type or null;

      # Check 1: allowed-use (allowlist)
      typeConflicts =
        if allowedUse != null && userType != null then
          if !(builtins.elem userType allowedUse) then
            [{ restriction = "allowed-use"; reason = "License only allows: ${builtins.concatStringsSep ", " allowedUse}"; }]
          else [ ]
        else [ ];

      # Check 2: restrictions (blocklist)
      restrictionConflicts = builtins.filter (c: c != null) (map
        (key:
          if (restrictions.${key} or false) && (usage.${key} or false) then
            { restriction = key; reason = "License prohibits ${key}"; }
          else null
        )
        (builtins.attrNames restrictions));

      allConflicts = typeConflicts ++ restrictionConflicts;

      # Obligations triggered by usage
      obligationChecks = builtins.concatMap
        (name:
          let
            triggers = obligations.${name} or [ ];
            matchedTriggers = builtins.filter
              (trigger: trigger == "any" || (usage.${trigger} or false))
              triggers;
          in
          if matchedTriggers != [ ] then
            [{ obligation = name; inherit triggers; }]
          else [ ]
        )
        (builtins.attrNames obligations);

    in
    {
      allowed = allConflicts == [ ];
      conflicts = allConflicts;
      obligations = obligationChecks;
    };

in
{
  inherit evaluateLicenseUsage;
}
