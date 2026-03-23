# Map nixpkgs license attrsets to SALT license data
#
# nixpkgs licenses: { shortName, spdxId, fullName, free, ... }
# SALT licenses: keyed by ScanCode key, with spdx_license_key
#
# Lookup order:
# 1. spdxId → salt.spdx.${spdxId}
# 2. Manual map for known mismatches
# 3. shortName → salt.licenses.${shortName}
# 4. throw (unknown license must fail)

{ saltLicenses, saltSpdx }:

let
  # nixpkgs shortName → SALT key for names that don't match directly
  manualMap = {
    # GPL variants
    "gpl2" = "gpl-2.0";
    "gpl2Only" = "gpl-2.0";
    "gpl2Plus" = "gpl-2.0";
    "gpl3" = "gpl-3.0";
    "gpl3Only" = "gpl-3.0";
    "gpl3Plus" = "gpl-3.0";

    # LGPL variants
    "lgpl2" = "lgpl-2.0";
    "lgpl2Only" = "lgpl-2.0";
    "lgpl21" = "lgpl-2.1";
    "lgpl21Only" = "lgpl-2.1";
    "lgpl21Plus" = "lgpl-2.1";
    "lgpl3" = "lgpl-3.0";
    "lgpl3Only" = "lgpl-3.0";
    "lgpl3Plus" = "lgpl-3.0";

    # AGPL
    "agpl3Only" = "agpl-3.0";
    "agpl3Plus" = "agpl-3.0";

    # Common renames
    "asl20" = "apache-2.0";
    "bsd2" = "bsd-simplified";
    "bsd3" = "bsd-new";
    "mpl20" = "mpl-2.0";
    "cc0" = "cc0-1.0";
    "psfl" = "python";
    "llgpl21" = "llgpl";

    # Unfree (nixpkgs concepts → closest SALT equivalents)
    "unfree" = "proprietary-license";
    "unfreeRedistributable" = "proprietary-redistributable";
    "unfreeRedistributableFirmware" = "proprietary-redistributable";
    "free" = "public-domain";
    "publicDomain" = "public-domain";

    # Specific vendor licenses
    "acsl14" = "proprietary-license";
    "activision" = "activision-eula";
    "amazonsl" = "amazon-sl";
    "amd" = "amd-historical";
    "aom" = "alliance-open-media-patent-1.0";
    "bsdAxisNoDisclaimerUnmodified" = "bsd-no-disclaimer-unmodified";
    "capec" = "proprietary-license";
    "cockroachdb-community-license" = "cockroachdb-2024-10-01";
    "databricks" = "databricks-db";
    "databricks-dbx" = "databricks-dbx-2021";
    "databricks-license" = "databricks-db";
    "eapl" = "proprietary-license";
    "epson" = "epson-avasys-pl-2008";
    "fairsource09" = "fair-source-0.9";
    "ffsl" = "ffsl-1";
    "g4sl" = "geant4-sl-1.0";
    "generaluser" = "generaluser-gs-2.0";
    "geogebra" = "geogebra-ncla-2022";
    "gfl" = "proprietary-license";
    "gfsl" = "proprietary-license";
    "hl3" = "hippocratic-3.0";
    "hpndDifferentDisclaimer" = "proprietary-license";
    "hpndSellVariantSafetyClause" = "proprietary-license";
    "intel-eula" = "intel-bcl";
    "issl" = "issl-2022";
    "lens" = "lens-tos-2023";
    "ncul1" = "proprietary-license";
    # Both nvidiaCuda and nvidiaCudaRedist have shortName "CUDA EULA"
    "obsidian" = "obsidian-tos-2025";
    "ocamlpro_nc" = "ocamlpro-nc-v1";
    "paratype" = "paratype-free-font-1.3";
    "postman" = "postman-tos-2024";
    "prosperity30" = "prosperity-3.0";
    "sfl" = "sfl-license";
    "stk" = "proprietary-license";
    "teamspeak" = "proprietary-license";
    "tekHvcLicense" = "proprietary-license";
    "tost" = "proprietary-license";
    "tsl" = "tsl-2020";
    "ucd" = "unicode-ucd";
    "virtualbox-puel" = "oracle-bcl-javase-platform-javafx-2017";
    "vol-sl" = "proprietary-license";
    "x11BsdClause" = "x11";
    "CUDA EULA" = "nvidia-cuda-supplement-2020";
    "TSL" = "tsl-2020";
  };

  lookup = nixpkgsLicense:
    let
      spdxId = nixpkgsLicense.spdxId or null;
      shortName = nixpkgsLicense.shortName or null;

      bySpdx = if spdxId != null then saltSpdx.${spdxId} or null else null;
      manualKey = if shortName != null then manualMap.${shortName} or null else null;
      byManual = if manualKey != null then saltLicenses.${manualKey} or null else null;
      byKey = if shortName != null then saltLicenses.${shortName} or null else null;
    in
    if bySpdx != null then bySpdx
    else if byManual != null then byManual
    else if byKey != null then byKey
    else null;

in
{
  inherit lookup manualMap;
}
