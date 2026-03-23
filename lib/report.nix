# License compliance report generator
#
# Produces a JSON report and HTML dashboard of all packages
# and their compliance status against the declared usage context.

{ lib, pkgs, licenseCheck, nixpkgsMap, mkUsageContext, cfg, ... }:

let
  evaluatePackage = pkg:
    let
      pname = pkg.pname or pkg.name or "unknown";
      version = pkg.version or "unknown";
      outputHash = builtins.unsafeDiscardStringContext (builtins.substring 11 32 (toString (pkg.outPath or "")));
      rawLicenses = lib.toList (pkg.meta.license or [ ]);
      hasLicense = rawLicenses != [ ];

      saltLicenses = map
        (nixLic:
          let salt = nixpkgsMap.lookup nixLic;
          in if salt != null then salt else { key = "unknown"; name = nixLic.fullName or nixLic.shortName or "unknown"; })
        rawLicenses;

      ctx = mkUsageContext pname;
      results = map
        (nixLic:
          let
            salt = nixpkgsMap.lookup nixLic;
          in
          if salt != null then licenseCheck.evaluateLicenseUsage ctx salt
          else { allowed = true; conflicts = [ ]; obligations = [ ]; })
        rawLicenses;

      allowed = builtins.all (r: r.allowed) results;
      conflicts = builtins.concatMap (r: r.conflicts) results;
      obligations = builtins.concatMap (r: r.obligations) results;

      hasOverride = cfg.licenses ? ${pname};
    in
    {
      inherit pname version outputHash hasLicense allowed hasOverride;
      licenses = map (s: { inherit (s) key name; }) saltLicenses;
      conflicts = map (c: { inherit (c) restriction reason; }) conflicts;
      obligations = map (o: { inherit (o) obligation triggers; }) obligations;
      status =
        if !hasLicense then "no-license"
        else if hasOverride then "overridden"
        else if allowed then "allowed"
        else "blocked";
    };

  mkReport = packages:
    let
      evaluated = map evaluatePackage packages;
      allowed = builtins.filter (p: p.status == "allowed") evaluated;
      blocked = builtins.filter (p: p.status == "blocked") evaluated;
      overridden = builtins.filter (p: p.status == "overridden") evaluated;
      noLicense = builtins.filter (p: p.status == "no-license") evaluated;
      usage = {
        inherit (cfg.usage) type commercial-use distribution modifications saas;
      };
      summary = {
        total = builtins.length evaluated;
        allowed = builtins.length allowed;
        blocked = builtins.length blocked;
        overridden = builtins.length overridden;
        noLicense = builtins.length noLicense;
      };
      # Hash the content for integrity
      contentHash = builtins.hashString "sha256"
        (builtins.toJSON { inherit usage summary; packages = map (p: p.pname) evaluated; });
    in
    {
      meta = {
        generator = "nix-license";
        version = lib.strings.trim (builtins.readFile ../version.txt);
        generatedAt = builtins.currentTime or 0;
        compliant = builtins.length blocked == 0;
        integrity = contentHash;
      };
      inherit usage summary;
      packages = evaluated;
    };

  mkReportFile = packages:
    pkgs.writeText "nix-license-report.json"
      (builtins.toJSON (mkReport packages));

  mkReportHtml = packages:
    let
      reportJson = builtins.toJSON (mkReport packages);
      template = builtins.readFile ./report-template.html;
      html = builtins.replaceStrings [ "__REPORT_JSON__" ] [ reportJson ] template;
    in
    pkgs.writeText "nix-license-report.html" html;

  mkReportBundle = packages:
    pkgs.runCommand "nix-license-report" { } ''
      mkdir -p $out
      cp ${mkReportFile packages} $out/report.json
      cp ${mkReportHtml packages} $out/index.html
    '';

in
{
  inherit mkReport mkReportFile mkReportHtml mkReportBundle;
}
