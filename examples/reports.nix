# Build reports from all examples
# Used by: nix build .#example-reports.<system>.personal

{ lib, pkgs, saltLicenses, saltSpdx, ... }:

let
  licenseCheck = import ../lib/licensing/check.nix { };
  nixpkgsMap = import ../lib/nixpkgs-map.nix { inherit saltLicenses saltSpdx; };

  # Packages to evaluate (covers permissive, copyleft, NC, proprietary)
  commonPackages = with pkgs; [
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

  # Default commitment/assurance values
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

  # Deep merge: preserve exceptions from defaults
  mergeWithDefaults = defaults: overrides:
    lib.mapAttrs
      (name: def:
        if overrides ? ${name} then def // overrides.${name}
        else def)
      defaults;

  # Build a report from an example config
  mkExampleReport = exampleFile:
    let
      nlCfg = (import exampleFile).nix-license;

      # Strip licenses (they reference local paths that don't exist in CI)
      rawCfg = builtins.removeAttrs nlCfg [ "licenses" "enable" "enforcement" ];

      commitments = mergeWithDefaults defaultCommitments
        (lib.mapAttrs
          (_: c: if builtins.isAttrs c then c else { fulfilled = c; exceptions = [ ]; })
          (rawCfg.commitments or { }));

      assurances = mergeWithDefaults defaultAssurances
        (lib.mapAttrs
          (_: a: if builtins.isAttrs a then a else { required = a; exceptions = [ ]; })
          (rawCfg.assurances or { }));

      cfg = {
        inherit (rawCfg) usage;
        inherit commitments assurances;
        licenses = { };
      };

      # Title from example name + description
      cfgName = nlCfg.name or "";
      cfgDesc = nlCfg.description or "";
      title =
        if cfgName != "" && cfgDesc != "" then "${cfgName} — ${cfgDesc}"
        else if cfgName != "" then cfgName
        else cfgDesc;

      licensingContext = import ../lib/licensing/context.nix { inherit lib; };
      mkUsageContext = licensingContext.mkUsageContext cfg;

      reportLib = import ../lib/commercial/reporting/report.nix {
        inherit lib pkgs licenseCheck nixpkgsMap mkUsageContext title cfg;
      };
    in
    reportLib.mkReportBundle commonPackages;

in
{
  personal = mkExampleReport ../examples/personal.nix;
  oss-developer = mkExampleReport ../examples/oss-developer.nix;
  saas = mkExampleReport ../examples/saas.nix;
  proprietary = mkExampleReport ../examples/proprietary.nix;
  educational = mkExampleReport ../examples/educational.nix;
  nonprofit = mkExampleReport ../examples/nonprofit.nix;
}
