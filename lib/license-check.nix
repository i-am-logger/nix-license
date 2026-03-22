# License compliance evaluation
#
# Five checks:
# 1. allowed-use: if license has an allowlist, user's type must be in it
# 2. restrictions: if license restricts an activity the user does, it's a conflict
# 3. commitments: if an obligation triggers and the user can't commit, it's a conflict
# 4. assurances: if the license disclaims something the user requires, it's a conflict
# 5. obligations: triggered obligations (informational)

_:

let
  evaluateLicenseUsage = usage: license:
    let
      restrictions = license.restrictions or { };
      obligations = license.obligations or { };
      disclaimers = license.disclaimers or [ ];
      allowedUse = license.allowed-use or license.allowedUsageTypes or null;
      userType = usage.type or null;

      # User policy
      commitments = usage.commitments or { };
      assurances = usage.assurances or { };

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

      # Check 3: commitments — triggered obligations the user can't fulfill
      commitmentConflicts = builtins.filter (c: c != null) (map
        (obl:
          if commitments ? ${obl.obligation} && !commitments.${obl.obligation} then
            { restriction = "commitment"; reason = "Cannot fulfill obligation '${obl.obligation}'"; }
          else null
        )
        obligationChecks);

      # Check 4: assurances — license disclaims something the user requires
      assuranceConflicts = builtins.filter (c: c != null) (map
        (key:
          let
            # Map assurance keys to disclaimer keys
            disclaimerKey =
              if key == "patent-grant" then "patent-use"
              else if key == "liability-coverage" then "liability"
              else key;
          in
          if (assurances.${key} or false) && builtins.elem disclaimerKey disclaimers then
            { restriction = "assurance"; reason = "License disclaims '${disclaimerKey}' but '${key}' is required"; }
          else null
        )
        (builtins.attrNames assurances));

      allConflicts = typeConflicts ++ restrictionConflicts ++ commitmentConflicts ++ assuranceConflicts;

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
