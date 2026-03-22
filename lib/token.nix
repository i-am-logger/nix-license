# License token operations
#
# Token construction, authorization evaluation, token restriction rules,
# and expiry checking. Actual Ed25519 signature verification
# is handled at build time via a derivation, not at eval time.

_:

let
  # ── Token construction ──────────────────────────────────────────

  # Create a license token
  mkLicenseToken =
    { issuer
    , licenseeId
    , licenseeName
    , package
    , version ? null
    , authorizations ? { }
    , validity ? { }
    }:
    {
      inherit issuer licenseeId licenseeName package version;
      inherit authorizations validity;
    };

  # Default authorizations (everything denied, quantities unlimited)
  defaultAuthorizations = {
    commercial = false;
    educational = false;
    government = false;
    military = false;
    redistribution = false;
    saas = false;
    modification = false;
    seats = 0; # 0 = not limited by this token
    machines = 0; # 0 = not limited by this token
  };

  # ── Authorization evaluation ────────────────────────────────────

  # Evaluate whether a token's authorizations satisfy a usage context
  # Returns: { satisfied = bool; mismatches = [ { field, required, granted } ]; }
  evaluateTokenAuthorizations = usage: authorizations:
    let
      auths = defaultAuthorizations // authorizations;

      isCommercial = (usage.type or "personal") == "commercial";
      isEducational = (usage.type or "personal") == "educational";
      isGovernment = (usage.type or "personal") == "government";
      isMilitary = usage.military or false;
      isRedistributing = usage.redistribution or false;
      isSaas = usage.saas or false;
      isModifying = usage.modification or false;

      checks = [
        { field = "commercial"; required = isCommercial; granted = auths.commercial; }
        { field = "educational"; required = isEducational; granted = auths.educational; }
        { field = "government"; required = isGovernment; granted = auths.government; }
        { field = "military"; required = isMilitary; granted = auths.military; }
        { field = "redistribution"; required = isRedistributing; granted = auths.redistribution; }
        { field = "saas"; required = isSaas; granted = auths.saas; }
        { field = "modification"; required = isModifying; granted = auths.modification or false; }
      ];

      # Seat and machine limits (0 = unlimited, checked separately)
      seatLimit = auths.seats or 0;
      machineLimit = auths.machines or 0;
      requestedSeats = usage.seats or 0;
      requestedMachines = usage.machines or 0;

      seatExceeded = seatLimit > 0 && requestedSeats > 0 && requestedSeats > seatLimit;
      machineExceeded = machineLimit > 0 && requestedMachines > 0 && requestedMachines > machineLimit;

      boolMismatches = builtins.filter
        (c: c.required && !c.granted)
        checks;

      quantityMismatches =
        (if seatExceeded then
          [{ field = "seats"; required = requestedSeats; granted = seatLimit; }]
        else [ ])
        ++ (if machineExceeded then
          [{ field = "machines"; required = requestedMachines; granted = machineLimit; }]
        else [ ]);

      mismatches = boolMismatches ++ quantityMismatches;
    in
    {
      satisfied = mismatches == [ ];
      inherit mismatches;
    };

  # ── Token restriction ───────────────────────────────────────────

  # Can this token be restricted to these new values?
  # Restriction rules (can only make MORE restrictive, never less):
  #   - Boolean true → can restrict to false
  #   - Boolean false → cannot escalate to true
  #   - Numeric value → can only decrease
  #   - Date string → can only make earlier (ISO 8601 lexicographic)
  #   - New keys can be added (additional restrictions)
  isValidTokenRestriction = original: restricted:
    let
      checkKey = key:
        if !(original ? ${key}) then
        # New key: always valid (adding a restriction)
          true
        else
          let
            origVal = original.${key};
            newVal = restricted.${key};
          in
          if builtins.isBool origVal && builtins.isBool newVal then
          # Bool: can only go true → false, not false → true
            if origVal then true
            else !newVal
          else if builtins.isInt origVal && builtins.isInt newVal then
          # Int: can only decrease
            newVal <= origVal
          else if builtins.isString origVal && builtins.isString newVal then
          # String (dates): can only make earlier
            newVal <= origVal
          else
          # Type mismatch: invalid
            false;

      restrictedKeys = builtins.attrNames restricted;
    in
    builtins.all checkKey restrictedKeys;

  # Apply a restriction to a token, returning the restricted token
  # Returns null if the restriction is invalid (would escalate permissions)
  restrictToken = original: restriction:
    if isValidTokenRestriction original restriction then
      original // restriction
    else
      null;

  # ── Expiry ──────────────────────────────────────────────────────

  # Is a token expired?
  isTokenExpired = currentDate: expiresAt:
    if expiresAt == null then
      { valid = true; expired = false; }
    else
      {
        valid = currentDate <= expiresAt;
        expired = currentDate > expiresAt;
      };

  # ── Content authorization in tokens ─────────────────────────────

  # Evaluate token content authorizations against a content policy
  # Token content fields are: content-<category> = "none"|"mild"|"moderate"|"intense"
  # Returns: { satisfied = bool; violations = [ { category, tokenLevel, policyLevel } ]; }
  evaluateTokenContentPolicy = contentPolicy: tokenContentAuths:
    let
      severityLevel = { "none" = 0; "mild" = 1; "moderate" = 2; "intense" = 3; };
      categories = builtins.filter
        (key: builtins.substring 0 8 key == "content-" && key != "content-allow-unrated")
        (builtins.attrNames tokenContentAuths);
      violations = builtins.filter (v: v != null)
        (map
          (key:
            let
              cat = builtins.substring 8 (builtins.stringLength key - 8) key;
              tokenLevel = tokenContentAuths.${key};
              policyLevel = contentPolicy.${cat} or "intense";
            in
            if (severityLevel.${tokenLevel} or 0) > (severityLevel.${policyLevel} or 3) then
              { category = cat; inherit tokenLevel policyLevel; }
            else
              null
          )
          categories);
    in
    {
      satisfied = violations == [ ];
      inherit violations;
    };

  # ── Full token validation ───────────────────────────────────────

  # Validate a token against a usage context (excluding signature verification)
  # Signature verification is handled at build time via a derivation
  validateToken =
    { claims
    , usage ? { type = "personal"; }
    , currentDate ? "9999-12-31"
    , requiredPackage ? null
    , contentPolicy ? null
    }:
    let
      authCheck = evaluateTokenAuthorizations usage claims.authorizations;
      expiryCheck = isTokenExpired currentDate (claims.validity.expires_at or null);
      packageMatch =
        if requiredPackage == null then true
        else claims.package == requiredPackage;

      # Check content authorizations if policy provided and token has content fields
      tokenContentAuths = claims.authorizations or { };
      hasContentFields = builtins.any
        (key: builtins.substring 0 8 key == "content-")
        (builtins.attrNames tokenContentAuths);
      contentCheck =
        if contentPolicy != null && hasContentFields then
          evaluateTokenContentPolicy contentPolicy tokenContentAuths
        else
          { satisfied = true; violations = [ ]; };
    in
    {
      valid = authCheck.satisfied && expiryCheck.valid && packageMatch && contentCheck.satisfied;
      authorizationsSatisfied = authCheck.satisfied;
      contentSatisfied = contentCheck.satisfied;
      inherit (authCheck) mismatches;
      contentViolations = contentCheck.violations;
      inherit (expiryCheck) expired;
      inherit packageMatch;
      licensee = claims.licenseeName;
      expiresAt = claims.validity.expires_at or null;
    };

in
{
  inherit
    mkLicenseToken
    defaultAuthorizations
    evaluateTokenAuthorizations
    evaluateTokenContentPolicy
    isValidTokenRestriction
    restrictToken
    isTokenExpired
    validateToken
    ;
}
