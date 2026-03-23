# Demo reports — evaluate common packages against each example config
# No packages are built or downloaded — only meta.license is evaluated

{ lib, pkgs, saltLicenses, saltSpdx, ... }:

let
  licenseCheck = import ../lib/license-check.nix { };
  nixpkgsMap = import ../lib/nixpkgs-map.nix { inherit saltLicenses saltSpdx; };

  # Common packages to evaluate (covers permissive, copyleft, NC, proprietary, source-available)
  demoPackages = with pkgs; [
    bash
    coreutils
    curl
    git
    firefox
    vim
    gcc
    python3
    openssh
    wget
    gnupg
    tmux
    htop
    jq
    ripgrep
    fd
    tree
  ];

  # Build a report for a given nix-license config
  mkDemoReport = name: nlCfg:
    let
      cfg = {
        inherit (nlCfg) usage;
        commitments = lib.mapAttrs
          (_: c:
            if builtins.isAttrs c then c
            else { fulfilled = c; exceptions = [ ]; }
          )
          (nlCfg.commitments or { });
        assurances = lib.mapAttrs
          (_: a:
            if builtins.isAttrs a then a
            else { required = a; exceptions = [ ]; }
          )
          (nlCfg.assurances or { });
        licenses = nlCfg.licenses or { };
      };

      # Fill in default commitments
      defaultCommitments = {
        include-copyright = { fulfilled = true; exceptions = [ ]; };
        disclose-source = { fulfilled = true; exceptions = [ ]; };
        same-license = { fulfilled = true; exceptions = [ ]; };
        same-license--file = { fulfilled = true; exceptions = [ ]; };
        same-license--library = { fulfilled = true; exceptions = [ ]; };
        document-changes = { fulfilled = true; exceptions = [ ]; };
        network-use-disclose = { fulfilled = true; exceptions = [ ]; };
      };
      defaultAssurances = {
        source-available = { required = false; exceptions = [ ]; };
        patent-grant = { required = false; exceptions = [ ]; };
        liability-coverage = { required = false; exceptions = [ ]; };
        warranty = { required = false; exceptions = [ ]; };
      };

      # Deep merge: preserve exceptions from defaults when override only sets fulfilled
      mergeWithDefaults = defaults: overrides:
        lib.mapAttrs
          (name: def:
            if overrides ? ${name} then
              def // overrides.${name}
            else def
          )
          defaults;

      fullCfg = {
        inherit (cfg) usage;
        commitments = mergeWithDefaults defaultCommitments cfg.commitments;
        assurances = mergeWithDefaults defaultAssurances cfg.assurances;
        inherit (cfg) licenses;
      };

      mkUsageContext = pname: fullCfg.usage // {
        commitments = lib.mapAttrs
          (_: c:
            let isExcepted = builtins.elem pname c.exceptions;
            in if c.fulfilled then !isExcepted else isExcepted)
          fullCfg.commitments;
        assurances = lib.mapAttrs
          (n: a:
            if n == "source-available" then false
            else a.required && !builtins.elem pname a.exceptions)
          fullCfg.assurances;
      };

      cfgName = nlCfg.name or "";
      cfgDesc = nlCfg.description or "";
      title =
        if cfgName != "" && cfgDesc != "" then "${cfgName} — ${cfgDesc}"
        else if cfgName != "" then cfgName
        else if cfgDesc != "" then cfgDesc
        else name;

      reportLib = import ../lib/report.nix {
        inherit lib pkgs licenseCheck nixpkgsMap mkUsageContext title;
        cfg = fullCfg;
      };
    in
    reportLib.mkReportBundle demoPackages;

  # Extract config from examples (strip licenses — they reference sops)
  stripLicenses = cfg: builtins.removeAttrs cfg [ "licenses" "enable" "enforcement" ];
  personalCfg = stripLicenses (import ../examples/personal.nix).nix-license;
  ossCfg = stripLicenses (import ../examples/oss-developer.nix).nix-license;
  educationalCfg = stripLicenses (import ../examples/educational.nix).nix-license;
  nonprofitCfg = stripLicenses (import ../examples/nonprofit.nix).nix-license;

  # Commercial examples — inline without sops references
  saasCfg = {
    usage = { type = "commercial"; commercial-use = true; distribution = true; modifications = true; saas = true; };
    commitments = {
      same-license.fulfilled = false;
      disclose-source.fulfilled = false;
      network-use-disclose.fulfilled = false;
    };
  };
  proprietaryCfg = {
    usage = { type = "commercial"; commercial-use = true; distribution = false; modifications = true; saas = false; };
    commitments = {
      same-license = { fulfilled = false; exceptions = [ "libfoo" ]; };
      disclose-source.fulfilled = false;
    };
    assurances.patent-grant = { required = true; exceptions = [ "legacy-lib" ]; };
  };

in
{
  personal = mkDemoReport "Personal — FOSS-only with NVIDIA exception" personalCfg;
  oss-developer = mkDemoReport "Open-source Developer" ossCfg;
  saas = mkDemoReport "SaaS Company — Docker Containers" saasCfg;
  proprietary = mkDemoReport "Commercial Company — Proprietary Product" proprietaryCfg;
  educational = mkDemoReport "Educational — University Lab" educationalCfg;
  nonprofit = mkDemoReport "Nonprofit Organization" nonprofitCfg;
}
