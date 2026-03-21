{
  description = "nix-license - NixOS license compliance module";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , treefmt-nix
    , git-hooks
    , ...
    }:
    let
      inherit (nixpkgs) lib;

      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = lib.genAttrs supportedSystems;

      treefmtEval = forAllSystems (system:
        treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} ./treefmt.nix
      );
    in
    {
      # Formatter (treefmt: nix + shell + yaml)
      formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);

      # Checks (run via `nix flake check`)
      checks = forAllSystems (system: {
        formatting = treefmtEval.${system}.config.build.check self;

        pre-commit = git-hooks.lib.${system}.run {
          src = self;
          hooks = {
            treefmt = {
              enable = true;
              package = treefmtEval.${system}.config.build.wrapper;
            };
            statix.enable = true;
            deadnix.enable = true;
          };
        };
      });

      # Dev shell with pre-commit hooks installed
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          inherit (self.checks.${system}) pre-commit;
        in
        {
          default = pkgs.mkShell {
            inherit (pre-commit) shellHook;
            buildInputs = pre-commit.enabledPackages ++ [
              pkgs.statix
              pkgs.deadnix
              pkgs.shellcheck
              pkgs.shfmt
              pkgs.nixpkgs-fmt
            ];
          };
        }
      );
    };
}
