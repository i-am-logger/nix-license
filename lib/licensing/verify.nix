# nix-license self-licensing gate
#
# When usage.commercial-use = true and enforcement = "enforce",
# a valid nix-license commercial license is required.
#
# Token format: GPG-signed JSON with claims:
#   { package = "nix-license"; commercial = true; licensee = "..."; expires_at = "..."; }
#
# Eval time: validate claims (package, commercial, expiry)
# Build time: verify GPG signature against embedded YubiKey public keys

{ lib, pkgs }:

let
  # Embedded author public keys (YubiKey pair, for key rotation)
  publicKeys = [
    ../../keys/yubikey1.asc
    ../../keys/yubikey2.asc
  ];

  # Parse a license JSON string into claims
  parseClaims = licenseJson:
    builtins.fromJSON licenseJson;

  # Validate license claims at eval time (no crypto, just structure + expiry)
  validateClaims = { claims, currentDate ? "9999-12-31" }:
    let
      isNixLicense = (claims.package or "") == "nix-license";
      isCommercial = claims.commercial or false;
      expiresAt = claims.expires_at or null;
      isExpired = expiresAt != null && currentDate > expiresAt;
      licensee = claims.licensee or "unknown";
    in
    {
      valid = isNixLicense && isCommercial && !isExpired;
      inherit isNixLicense isCommercial isExpired licensee expiresAt;
      errors =
        (if !isNixLicense then [ "Token is not for nix-license (package = '${claims.package or "missing"}')" ] else [ ])
        ++ (if !isCommercial then [ "Token does not grant commercial use" ] else [ ])
        ++ (if isExpired then [ "Token expired on ${expiresAt}" ] else [ ]);
    };

  # Build-time GPG signature verification derivation
  # Takes the license file (detached signature) and verifies against embedded public keys
  mkVerifyDerivation = { licenseFile, signatureFile ? null }:
    let
      sigFile =
        if signatureFile != null then signatureFile
        else "${licenseFile}.sig";
    in
    pkgs.runCommand "nix-license-verify"
      {
        nativeBuildInputs = [ pkgs.gnupg ];
      } ''
      export GNUPGHOME=$(mktemp -d)

      # Import all author public keys
      ${lib.concatMapStringsSep "\n" (key: "gpg --import ${key}") publicKeys}

      # Verify the signature
      if gpg --trust-model always --verify ${sigFile} ${licenseFile}; then
        echo "nix-license: license signature verified" > $out
      else
        echo "nix-license: INVALID license signature"
        exit 1
      fi
    '';

  # Build-time vendor token verification (algorithm-agnostic via openssl)
  # Vendors provide PEM public keys — any algorithm openssl supports
  # (Ed25519, RSA, ECDSA, etc.)
  mkVendorVerifyDerivation = { licenseFile, signatureFile, publicKeyFile }:
    pkgs.runCommand "nix-license-verify-vendor"
      {
        nativeBuildInputs = [ pkgs.openssl ];
      } ''
      if openssl pkeyutl -verify \
        -pubin -inkey ${publicKeyFile} \
        -sigfile ${signatureFile} \
        -rawin -in ${licenseFile}; then
        echo "nix-license: vendor license signature verified" > $out
      else
        echo "nix-license: INVALID vendor license signature"
        exit 1
      fi
    '';

in
{
  inherit publicKeys parseClaims validateClaims mkVerifyDerivation mkVendorVerifyDerivation;
}
