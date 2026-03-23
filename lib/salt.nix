# License definitions from SALT (Software And License Taxonomy)
#
# SALT provides 2649 licenses with grants, obligations, restrictions,
# and disclaimers. nix-license uses SALT terms directly — no mapping.

{ saltLicenses, ... }:

let
  # Convert a SALT license to nix-license format
  # SALT terms are used as-is; we only add the `free` field
  fromSalt = saltLicense: {
    inherit (saltLicense) grants obligations restrictions disclaimers;
    spdxId = saltLicense.spdx_license_key or null;
    fullName = saltLicense.name;
    # A license is "free" if it grants commercial use and has no restrictions
    free = builtins.elem "commercial-use" (saltLicense.grants or [ ])
      && (saltLicense.restrictions or { }) == { };
  };

  allLicenses = builtins.mapAttrs (_: fromSalt) saltLicenses;

in
allLicenses // {
  # SALT term enums for reference
  allRestrictions = [ "commercial-use" "distribution" "modifications" ];
  allObligations = [ "include-copyright" "disclose-source" "network-use-disclose" "same-license" "same-license--file" "same-license--library" "document-changes" ];
  allGrants = [ "commercial-use" "modifications" "distribution" "patent-use" "private-use" ];
  allDisclaimers = [ "liability" "warranty" "patent-use" "trademark-use" ];

  _meta = {
    licenseCount = builtins.length (builtins.attrNames saltLicenses);
    source = "salt";
  };
}
