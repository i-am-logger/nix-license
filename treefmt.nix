_:
{
  projectRootFile = "flake.nix";

  programs = {
    nixpkgs-fmt.enable = true;
    shfmt.enable = true;
    shellcheck.enable = true;
    yamlfmt.enable = true;
  };
}
