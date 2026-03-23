# Tests for lib/license.nix
# Cryptographic token authorization, restriction, and validation logic

_:

let
  lc = import ../../lib/licensing/license.nix { };

  assertTrue = name: value:
    if value then true
    else throw "FAIL: ${name}: expected true";

  assertFalse = name: value:
    if !value then true
    else throw "FAIL: ${name}: expected false";

  assertEq = name: actual: expected:
    if actual == expected then true
    else throw "FAIL: ${name}: expected ${builtins.toJSON expected}, got ${builtins.toJSON actual}";

  assertNull = name: value:
    if value == null then true
    else throw "FAIL: ${name}: expected null, got ${builtins.toJSON value}";

  # ── Test fixtures ───────────────────────────────────────────────

  fullToken = lc.mkLicense {
    issuer = "vendor.example.com";
    licenseeId = "org-12345";
    licenseeName = "Acme Corp";
    package = "vendor-sdk";
    version = ">= 2.0";
    authorizations = {
      commercial = true;
      educational = true;
      government = true;
      military = false;
      redistribution = false;
      saas = true;
      modification = true;
      seats = 25;
      machines = 100;
    };
    validity = {
      issued_at = "2024-06-15";
      expires_at = "2025-06-15";
    };
  };

  educationalToken = lc.mkLicense {
    issuer = "vendor.example.com";
    licenseeId = "edu-67890";
    licenseeName = "State University";
    package = "vendor-sdk";
    authorizations = {
      commercial = false;
      educational = true;
      government = false;
      military = false;
      redistribution = false;
      saas = false;
      modification = true;
    };
    validity = {
      issued_at = "2024-01-01";
      expires_at = "2026-08-31";
    };
  };

  minimalToken = lc.mkLicense {
    issuer = "small-vendor.io";
    licenseeId = "user-1";
    licenseeName = "Alice";
    package = "small-tool";
    authorizations = {
      commercial = true;
    };
    validity = { };
  };

in
{
  # ══════════════════════════════════════════════════════════════════
  # TOKEN CONSTRUCTION
  # ══════════════════════════════════════════════════════════════════

  mkTokenHasIssuer = assertEq "token has issuer"
    fullToken.issuer "vendor.example.com";

  mkTokenHasLicensee = assertEq "token has licensee"
    fullToken.licenseeName "Acme Corp";

  mkTokenHasPackage = assertEq "token has package"
    fullToken.package "vendor-sdk";

  mkTokenHasVersion = assertEq "token has version"
    fullToken.version ">= 2.0";

  mkTokenHasAuthorizations = assertTrue "token has authorizations"
    fullToken.authorizations.commercial;

  mkTokenHasValidity = assertEq "token has expiry"
    fullToken.validity.expires_at "2025-06-15";

  mkTokenMinimal = assertEq "minimal token has issuer"
    minimalToken.issuer "small-vendor.io";

  mkTokenMinimalNoExpiry = assertFalse "minimal token has no expiry"
    (minimalToken.validity ? expires_at);

  # ══════════════════════════════════════════════════════════════════
  # AUTHORIZATION MATCHING
  # ══════════════════════════════════════════════════════════════════

  # Full token satisfies commercial use
  authCommercialSatisfied =
    let result = lc.evaluateAuthorizations { type = "commercial"; } fullToken.authorizations;
    in assertTrue "full token satisfies commercial" result.satisfied;

  # Full token satisfies commercial + SaaS
  authCommercialSaasSatisfied =
    let result = lc.evaluateAuthorizations { type = "commercial"; saas = true; } fullToken.authorizations;
    in assertTrue "full token satisfies commercial+saas" result.satisfied;

  # Full token does NOT satisfy military
  authMilitaryUnsatisfied =
    let result = lc.evaluateAuthorizations { type = "commercial"; military = true; } fullToken.authorizations;
    in assertFalse "full token denies military" result.satisfied;

  # Full token does NOT satisfy redistribution
  authRedistUnsatisfied =
    let result = lc.evaluateAuthorizations { type = "personal"; redistribution = true; } fullToken.authorizations;
    in assertFalse "full token denies redistribution" result.satisfied;

  # Educational token satisfies educational use
  authEducationalSatisfied =
    let result = lc.evaluateAuthorizations { type = "educational"; } educationalToken.authorizations;
    in assertTrue "edu token satisfies educational" result.satisfied;

  # Educational token does NOT satisfy commercial
  authEducationalCommercialUnsatisfied =
    let result = lc.evaluateAuthorizations { type = "commercial"; } educationalToken.authorizations;
    in assertFalse "edu token denies commercial" result.satisfied;

  # Personal use always satisfied (no special requirements)
  authPersonalAlwaysSatisfied =
    let result = lc.evaluateAuthorizations { type = "personal"; } fullToken.authorizations;
    in assertTrue "personal always satisfied" result.satisfied;

  # Mismatch details
  authMismatchDetails =
    let result = lc.evaluateAuthorizations { type = "commercial"; military = true; } fullToken.authorizations;
    in assertTrue "mismatch lists military"
      (builtins.any (m: m.field == "military") result.mismatches);

  authMismatchCount =
    let
      result = lc.evaluateAuthorizations
        { type = "commercial"; military = true; redistribution = true; }
        fullToken.authorizations;
    in
    assertEq "two mismatches" (builtins.length result.mismatches) 2;

  # Empty authorizations deny everything
  authEmptyDeniesCommercial =
    let result = lc.evaluateAuthorizations { type = "commercial"; } { };
    in assertFalse "empty auths deny commercial" result.satisfied;

  authEmptyAllowsPersonal =
    let result = lc.evaluateAuthorizations { type = "personal"; } { };
    in assertTrue "empty auths allow personal" result.satisfied;

  # ══════════════════════════════════════════════════════════════════
  # TOKEN RESTRICTION
  # ══════════════════════════════════════════════════════════════════

  # Valid restrictions
  canRestrictTrueToFalse = assertTrue "can restrict true -> false"
    (lc.isValidRestriction
      { commercial = true; military = true; }
      { military = false; });

  canKeepTrueAsTrue = assertTrue "can keep true -> true"
    (lc.isValidRestriction
      { commercial = true; }
      { commercial = true; });

  canKeepFalseAsFalse = assertTrue "can keep false -> false"
    (lc.isValidRestriction
      { military = false; }
      { military = false; });

  canDecreaseIntLimit = assertTrue "can decrease int"
    (lc.isValidRestriction
      { seats = 500; }
      { seats = 50; });

  canKeepIntSame = assertTrue "can keep int same"
    (lc.isValidRestriction
      { seats = 500; }
      { seats = 500; });

  canShortenExpiry = assertTrue "can make date earlier"
    (lc.isValidRestriction
      { expires_at = "2025-12-31"; }
      { expires_at = "2025-06-15"; });

  canKeepExpirySame = assertTrue "can keep date same"
    (lc.isValidRestriction
      { expires_at = "2025-12-31"; }
      { expires_at = "2025-12-31"; });

  canAddNewRestriction = assertTrue "can add new restriction"
    (lc.isValidRestriction
      { commercial = true; }
      { commercial = true; machine_pattern = "dev-*"; });

  canRestrictToEmpty = assertTrue "can restrict to empty (no changes)"
    (lc.isValidRestriction
      { commercial = true; seats = 500; }
      { });

  # Invalid restrictions
  cannotGrantFalseToTrue = assertFalse "cannot grant false -> true"
    (lc.isValidRestriction
      { military = false; }
      { military = true; });

  cannotIncreaseIntLimit = assertFalse "cannot increase int"
    (lc.isValidRestriction
      { seats = 50; }
      { seats = 500; });

  cannotExtendExpiry = assertFalse "cannot make date later"
    (lc.isValidRestriction
      { expires_at = "2025-06-15"; }
      { expires_at = "2025-12-31"; });

  # Apply restriction
  applyRestrictionValid =
    let
      original = { commercial = true; military = true; seats = 500; };
      restriction = { military = false; seats = 50; };
      result = lc.restrictLicense original restriction;
    in
    assertTrue "valid restriction applied"
      (result != null
        && result.commercial
        && !result.military
        && result.seats == 50);

  applyRestrictionInvalid =
    let
      original = { military = false; };
      restriction = { military = true; };
      result = lc.restrictLicense original restriction;
    in
    assertNull "invalid restriction returns null" result;

  # ══════════════════════════════════════════════════════════════════
  # EXPIRY
  # ══════════════════════════════════════════════════════════════════

  expiryValid = assertTrue "not expired"
    (lc.isExpired "2024-12-03" "2025-06-15").valid;

  expiryExpired = assertFalse "expired"
    (lc.isExpired "2025-07-01" "2025-06-15").valid;

  expiryOnDate = assertTrue "valid on exact expiry date"
    (lc.isExpired "2025-06-15" "2025-06-15").valid;

  expiryNull = assertTrue "no expiry = always valid"
    (lc.isExpired "2099-01-01" null).valid;

  expiryExpiredFlag = assertTrue "expired flag set"
    (lc.isExpired "2025-07-01" "2025-06-15").expired;

  expiryNotExpiredFlag = assertFalse "expired flag not set"
    (lc.isExpired "2024-12-03" "2025-06-15").expired;

  # ══════════════════════════════════════════════════════════════════
  # FULL TOKEN VALIDATION
  # ══════════════════════════════════════════════════════════════════

  validateFullValid =
    let
      result = lc.validateLicense {
        claims = fullToken;
        usage = { type = "commercial"; saas = true; };
        currentDate = "2024-12-03";
        requiredPackage = "vendor-sdk";
      };
    in
    assertTrue "full validation passes" result.valid;

  validateWrongPackage =
    let
      result = lc.validateLicense {
        claims = fullToken;
        usage = { type = "commercial"; };
        currentDate = "2024-12-03";
        requiredPackage = "other-package";
      };
    in
    assertFalse "wrong package fails" result.valid;

  validateExpiredToken =
    let
      result = lc.validateLicense {
        claims = fullToken;
        usage = { type = "commercial"; };
        currentDate = "2026-01-01";
        requiredPackage = "vendor-sdk";
      };
    in
    assertFalse "expired token fails" result.valid;

  validateInsufficientAuth =
    let
      result = lc.validateLicense {
        claims = fullToken;
        usage = { type = "commercial"; military = true; };
        currentDate = "2024-12-03";
      };
    in
    assertFalse "insufficient auth fails" result.valid;

  validateLicenseeReturned =
    let
      result = lc.validateLicense {
        claims = fullToken;
        usage = { type = "personal"; };
        currentDate = "2024-12-03";
      };
    in
    assertEq "licensee returned" result.licensee "Acme Corp";

  validateExpiryReturned =
    let
      result = lc.validateLicense {
        claims = fullToken;
        usage = { type = "personal"; };
        currentDate = "2024-12-03";
      };
    in
    assertEq "expiry returned" result.expiresAt "2025-06-15";

  validateNoPackageCheck =
    let
      result = lc.validateLicense {
        claims = fullToken;
        usage = { type = "commercial"; };
        currentDate = "2024-12-03";
      };
    in
    assertTrue "no package check = passes" result.valid;

  # Educational token
  validateEduValid =
    let
      result = lc.validateLicense {
        claims = educationalToken;
        usage = { type = "educational"; };
        currentDate = "2025-01-01";
      };
    in
    assertTrue "edu token valid for educational" result.valid;

  validateEduCommercialFails =
    let
      result = lc.validateLicense {
        claims = educationalToken;
        usage = { type = "commercial"; };
        currentDate = "2025-01-01";
      };
    in
    assertFalse "edu token fails for commercial" result.valid;

  # ══════════════════════════════════════════════════════════════════
  # TOKEN RESTRICTION PROPERTIES
  # ══════════════════════════════════════════════════════════════════

  # Reflexivity: restricting with identity (same values) is valid
  tokenCanAlwaysBeRestrictedToItself =
    let
      auths = { commercial = true; military = false; seats = 100; expires_at = "2025-12-31"; };
    in
    assertTrue "token restriction is reflexive (identity is valid)"
      (lc.isValidRestriction auths auths);

  # Transitivity: if A restricts to B and B restricts to C, then A restricts to C
  chainedTokenRestrictionsAreValid =
    let
      a = { commercial = true; military = true; seats = 500; expires_at = "2025-12-31"; };
      b = { commercial = true; military = false; seats = 200; expires_at = "2025-06-15"; };
      c = { commercial = false; military = false; seats = 50; expires_at = "2025-03-01"; };
    in
    assertTrue "token restriction is transitive (A->B, B->C implies A->C)"
      (lc.isValidRestriction a b
        && lc.isValidRestriction b c
        && lc.isValidRestriction a c);

  # Antisymmetry: if A restricts to B and B restricts to A, then A = B
  restrictionAntisymmetric =
    let
      a = { commercial = true; seats = 100; };
      b = { commercial = true; seats = 100; };
      c = { commercial = true; seats = 50; };
    in
    assertTrue "token restriction is antisymmetric"
      ((lc.isValidRestriction a b && lc.isValidRestriction b a)  # a = b, both directions valid
        && !(lc.isValidRestriction c a && lc.isValidRestriction a c)); # a != c, not both directions

  # Monotonicity: if restriction A->B is valid, then for any usage that B satisfies, A also satisfies
  restrictedTokenNeverGrantsMoreThanOriginal =
    let
      original = {
        commercial = true;
        educational = true;
        military = true;
        redistribution = true;
        saas = true;
      };
      restricted = {
        commercial = true;
        educational = true;
        military = false;
        redistribution = false;
        saas = false;
      };
      usages = [
        { type = "personal"; }
        { type = "commercial"; }
        { type = "educational"; }
        { type = "commercial"; saas = true; }
        { type = "commercial"; military = true; }
        { type = "personal"; redistribution = true; }
      ];
    in
    assertTrue "restricted token never grants more than original"
      (lc.isValidRestriction original restricted
        && builtins.all
        (u:
          let
            restrictedSatisfied = (lc.evaluateAuthorizations u restricted).satisfied;
            origSatisfied = (lc.evaluateAuthorizations u original).satisfied;
          in
          if restrictedSatisfied then origSatisfied else true
        )
        usages);

  # Bottom element: all-false/zero is the most restricted possible
  mostRestrictedTokenIsAlwaysValid =
    let
      any = { commercial = true; military = true; seats = 500; };
      bottom = { commercial = false; military = false; seats = 0; };
    in
    assertTrue "all-false/zero is always a valid restriction"
      (lc.isValidRestriction any bottom);

  # Top element: the original is always a valid self-restriction
  tokenIsAlwaysValidRestrictionOfItself =
    let
      any = { commercial = true; military = false; seats = 100; };
    in
    assertTrue "identity is always a valid restriction"
      (lc.isValidRestriction any any);

  # Cannot escalate: no single field can be made more permissive
  restrictionCannotEscalatePermissions =
    let
      boolPairs = [
        { orig = false; att = true; }
      ];
      intPairs = [
        { orig = 50; att = 100; }
        { orig = 0; att = 1; }
      ];
      datePairs = [
        { orig = "2025-01-01"; att = "2025-12-31"; }
        { orig = "2024-06-15"; att = "2024-06-16"; }
      ];
    in
    assertTrue "no field can be escalated"
      (builtins.all (p: !lc.isValidRestriction { x = p.orig; } { x = p.att; }) boolPairs
        && builtins.all (p: !lc.isValidRestriction { x = p.orig; } { x = p.att; }) intPairs
        && builtins.all (p: !lc.isValidRestriction { x = p.orig; } { x = p.att; }) datePairs);

  # ══════════════════════════════════════════════════════════════════
  # EXHAUSTIVE: all authorization fields x all usage contexts
  # ══════════════════════════════════════════════════════════════════

  authFieldsCrossProduct =
    let
      authFields = [ "commercial" "educational" "government" "military" "redistribution" "saas" ];
      usages = [
        { type = "personal"; }
        { type = "commercial"; }
        { type = "educational"; }
        { type = "government"; }
        { type = "personal"; redistribution = true; }
        { type = "commercial"; saas = true; }
        { type = "commercial"; military = true; }
        { type = "government"; military = true; }
      ];

      # For each auth field being the only true one, test all usage contexts
      results = builtins.concatMap
        (field:
          let
            auths = builtins.listToAttrs
              (map (f: { name = f; value = f == field; }) authFields);
          in
          map
            (u:
              let result = lc.evaluateAuthorizations u auths;
              in result ? satisfied && result ? mismatches
            )
            usages
        )
        authFields;
    in
    assertTrue "all auth fields x usage contexts produce valid results"
      (builtins.all (x: x) results);

  # ══════════════════════════════════════════════════════════════════
  # MODIFICATION, SEATS, MACHINES CHECKS
  # ══════════════════════════════════════════════════════════════════

  # Modification authorization
  authModificationRequired =
    let
      result = lc.evaluateAuthorizations
        { type = "personal"; modification = true; }
        { modification = false; };
    in
    assertFalse "modification denied when not authorized" result.satisfied;

  authModificationGranted =
    let
      result = lc.evaluateAuthorizations
        { type = "personal"; modification = true; }
        { modification = true; };
    in
    assertTrue "modification allowed when authorized" result.satisfied;

  # Seat limits
  authSeatsWithinLimit =
    let
      result = lc.evaluateAuthorizations
        { type = "commercial"; seats = 10; }
        { commercial = true; seats = 25; };
    in
    assertTrue "seats within limit" result.satisfied;

  authSeatsExceedLimit =
    let
      result = lc.evaluateAuthorizations
        { type = "commercial"; seats = 50; }
        { commercial = true; seats = 25; };
    in
    assertFalse "seats exceed limit" result.satisfied;

  authSeatsExactLimit =
    let
      result = lc.evaluateAuthorizations
        { type = "commercial"; seats = 25; }
        { commercial = true; seats = 25; };
    in
    assertTrue "seats at exact limit" result.satisfied;

  authSeatsUnlimited =
    let
      result = lc.evaluateAuthorizations
        { type = "commercial"; seats = 1000; }
        { commercial = true; seats = 0; };
    in
    assertTrue "seats=0 means not limited" result.satisfied;

  # Machine limits
  authMachinesWithinLimit =
    let
      result = lc.evaluateAuthorizations
        { type = "commercial"; machines = 5; }
        { commercial = true; machines = 100; };
    in
    assertTrue "machines within limit" result.satisfied;

  authMachinesExceedLimit =
    let
      result = lc.evaluateAuthorizations
        { type = "commercial"; machines = 200; }
        { commercial = true; machines = 100; };
    in
    assertFalse "machines exceed limit" result.satisfied;

  # Seat mismatch details
  authSeatMismatchDetails =
    let
      result = lc.evaluateAuthorizations
        { type = "commercial"; seats = 50; }
        { commercial = true; seats = 25; };
    in
    assertTrue "seat mismatch in details"
      (builtins.any (m: m.field == "seats") result.mismatches);

  # ══════════════════════════════════════════════════════════════════
  # CONTENT AUTHORIZATION IN TOKENS
  # ══════════════════════════════════════════════════════════════════

  contentAuthSatisfied =
    let
      result = lc.evaluateContentPolicy
        { violence-cartoon = "moderate"; social-chat = "mild"; }
        { content-violence-cartoon = "mild"; content-social-chat = "none"; };
    in
    assertTrue "content auth within policy" result.satisfied;

  contentAuthViolated =
    let
      result = lc.evaluateContentPolicy
        { violence-cartoon = "mild"; }
        { content-violence-cartoon = "intense"; };
    in
    assertFalse "content auth exceeds policy" result.satisfied;

  contentAuthViolationDetails =
    let
      result = lc.evaluateContentPolicy
        { violence-cartoon = "mild"; }
        { content-violence-cartoon = "intense"; };
    in
    assertTrue "content violation has category"
      (builtins.any (v: v.category == "violence-cartoon") result.violations);

  contentAuthIgnoresNonContent =
    let
      result = lc.evaluateContentPolicy
        { violence-cartoon = "mild"; }
        { commercial = true; content-violence-cartoon = "mild"; };
    in
    assertTrue "non-content fields ignored" result.satisfied;

  contentAuthAllowUnratedIgnored =
    let
      result = lc.evaluateContentPolicy
        { violence-cartoon = "intense"; }
        { content-allow-unrated = "false"; content-violence-cartoon = "mild"; };
    in
    assertTrue "allow-unrated key filtered out" result.satisfied;

  # Full validation with content policy
  validateWithContentPolicy =
    let
      claims = lc.mkLicense {
        issuer = "test";
        licenseeId = "1";
        licenseeName = "Test";
        package = "test-app";
        authorizations = {
          commercial = true;
          content-violence-cartoon = "intense";
          content-social-chat = "moderate";
        };
      };
      result = lc.validateLicense {
        inherit claims;
        usage = { type = "commercial"; };
        contentPolicy = { violence-cartoon = "mild"; social-chat = "intense"; };
      };
    in
    assertFalse "content policy violation fails full validation" result.valid;

  validateWithContentPolicyPass =
    let
      claims = lc.mkLicense {
        issuer = "test";
        licenseeId = "1";
        licenseeName = "Test";
        package = "test-app";
        authorizations = {
          commercial = true;
          content-violence-cartoon = "mild";
        };
      };
      result = lc.validateLicense {
        inherit claims;
        usage = { type = "commercial"; };
        contentPolicy = { violence-cartoon = "moderate"; };
      };
    in
    assertTrue "content policy satisfied passes full validation" result.valid;

  validateNoContentPolicy =
    let
      result = lc.validateLicense {
        claims = fullToken;
        usage = { type = "commercial"; };
        currentDate = "2024-12-03";
      };
    in
    assertTrue "no content policy = passes content check" result.contentSatisfied;
}
