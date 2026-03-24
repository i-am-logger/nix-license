# Tests for lib/self-license.nix
# Eval-time token claim validation

{ lib }:

let
  sl = import ../../lib/licensing/verify.nix { inherit lib; pkgs = { }; };

  assertTrue = name: value:
    if value then true
    else throw "FAIL: ${name}";

  assertFalse = name: value:
    if !value then true
    else throw "FAIL: ${name}";

  assertEq = name: actual: expected:
    if actual == expected then true
    else throw "FAIL: ${name}: expected ${builtins.toJSON expected}, got ${builtins.toJSON actual}";

  # Test token (same as fixtures/nix-license-commercial-license.json)
  validClaims = {
    package = "nix-license";
    commercial = true;
    licensee = "Test Corp";
    licensee_id = "test-001";
    issued_at = "2026-03-22";
    expires_at = "2027-03-22";
  };

in
{
  # ── Valid token ───────────────────────────────────────────────

  validTokenPasses =
    let result = sl.validateClaims { claims = validClaims; currentDate = "2026-06-01"; };
    in assertTrue "valid license passes" result.valid;

  validTokenLicensee =
    let result = sl.validateClaims { claims = validClaims; };
    in assertEq "licensee is Test Corp" result.licensee "Test Corp";

  validTokenNotExpired =
    let result = sl.validateClaims { claims = validClaims; currentDate = "2026-06-01"; };
    in assertFalse "not expired" result.isExpired;

  # ── Wrong package ─────────────────────────────────────────────

  wrongPackageFails =
    let result = sl.validateClaims { claims = validClaims // { package = "other-tool"; }; };
    in assertFalse "wrong package fails" result.valid;

  wrongPackageError =
    let result = sl.validateClaims { claims = validClaims // { package = "other-tool"; }; };
    in assertTrue "wrong package has error"
      (builtins.length result.errors > 0);

  # ── Not commercial ────────────────────────────────────────────

  nonCommercialFails =
    let result = sl.validateClaims { claims = validClaims // { commercial = false; }; };
    in assertFalse "non-commercial fails" result.valid;

  # ── Expired ───────────────────────────────────────────────────

  expiredTokenFails =
    let result = sl.validateClaims { claims = validClaims; currentDate = "2028-01-01"; };
    in assertFalse "expired license fails" result.valid;

  expiredTokenIsExpired =
    let result = sl.validateClaims { claims = validClaims; currentDate = "2028-01-01"; };
    in assertTrue "expired flag set" result.isExpired;

  notYetExpired =
    let result = sl.validateClaims { claims = validClaims; currentDate = "2027-03-22"; };
    in assertTrue "exact expiry date still valid" result.valid;

  # ── No expiry ─────────────────────────────────────────────────

  noExpiryNeverExpires =
    let
      claims = builtins.removeAttrs validClaims [ "expires_at" ];
      result = sl.validateClaims { inherit claims; currentDate = "2099-12-31"; };
    in
    assertTrue "no expiry = never expires" result.valid;

  # ── Parse claims ──────────────────────────────────────────────

  parseClaimsRoundtrip =
    let
      json = builtins.toJSON validClaims;
      parsed = sl.parseClaims json;
    in
    assertEq "parse roundtrip" parsed.package "nix-license";

  # ── Missing fields ────────────────────────────────────────────

  missingPackageFails =
    let result = sl.validateClaims { claims = { commercial = true; }; };
    in assertFalse "missing package fails" result.valid;

  missingCommercialFails =
    let result = sl.validateClaims { claims = { package = "nix-license"; }; };
    in assertFalse "missing commercial fails" result.valid;

  emptyClaimsFails =
    let result = sl.validateClaims { claims = { }; };
    in assertFalse "empty claims fails" result.valid;
}
