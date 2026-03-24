{
  description = "nix-license - NixOS license compliance module";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # OARS 1.1 specification (source of truth for content rating categories)
    oars = {
      url = "github:hughsie/oars";
      flake = false;
    };

    # SALT (source of truth for license classifications)
    salt = {
      url = "github:i-am-logger/salt";
    };

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
    , oars
    , salt
    , treefmt-nix
    , git-hooks
    , ...
    }:
    let
      inherit (nixpkgs) lib;

      # Parse OARS 1.1 RNC schema to extract category IDs and severity values
      oarsSpec =
        let
          rnc = builtins.readFile "${oars}/specification/oars-1.1.rnc";

          # Extract the ids block: everything between 'ids = "' and the last '"'
          # The RNC format is: ids = "id1" | \n      "id2" | ...
          idsBlock =
            let
              parts = lib.splitString "ids = " rnc;
              raw = builtins.elemAt parts 1;
            in
            raw;

          # Extract quoted strings from the ids block
          extractQuoted = s:
            let
              parts = lib.splitString "\"" s;
              indexed = lib.imap0 (i: v: { inherit i v; }) parts;
              oddParts = builtins.filter (x: lib.mod x.i 2 == 1) indexed;
            in
            map (x: x.v) oddParts;

          # Extract severity values from the values line
          valuesBlock =
            let
              parts = lib.splitString "values = " rnc;
              raw = builtins.elemAt parts 1;
              line = builtins.head (lib.splitString "\n" raw);
            in
            extractQuoted line;

          categories = extractQuoted idsBlock;
        in
        {
          version = "oars-1.1";
          inherit categories;
          severityValues = valuesBlock;
        };

      # SALT license taxonomy
      saltLicenses = salt.licenses;
      saltSpdx = salt.spdx;

      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = lib.genAttrs supportedSystems;

      treefmtEval = forAllSystems (system:
        treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} ./treefmt.nix
      );
    in
    {
      # Library functions
      lib = import ./lib { inherit lib oarsSpec saltLicenses; };

      # NixOS modules (extra args closed over from the flake via _module.args)
      nixosModules = {
        # Standalone module: provides nix-license.* options
        default = {
          imports = [ ./modules/default.nix ];
          _module.args = { inherit oarsSpec saltLicenses saltSpdx; };
        };

        # mynixos integration: provides my.license.* and my.users.<name>.contentPolicy
        # Includes default module — only one import needed
        mynixos = {
          imports = [ ./modules/default.nix ./modules/mynixos.nix ];
          _module.args = { inherit oarsSpec saltLicenses saltSpdx; };
        };
      };

      # Example reports — build with: nix build .#example-reports.<system>.personal
      example-reports = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in import ./examples/reports.nix { inherit lib pkgs saltLicenses saltSpdx; }
      );

      # Formatter (treefmt: nix + shell + yaml)
      formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);

      # Checks (run via `nix flake check`)
      checks = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          # Evaluate a test file at Nix eval time, build a derivation that
          # succeeds only if all assertions pass (any throw = eval failure)
          mkNixTest = name: results:
            let
              # Force evaluation of all test results — tests throw on failure
              count = builtins.length (builtins.attrValues results);
            in
            pkgs.runCommand "nix-license-test-${name}" { } ''
              echo "${name}: ${toString count} tests passed"
              echo "${name}: ${toString count} tests passed" > $out
            '';
        in
        {
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

          # Library tests
          content-rating-types = mkNixTest "content-rating-types"
            (import ./tests/content-rating/types.nix { inherit lib oarsSpec; });

          content-rating = mkNixTest "content-rating"
            (import ./tests/content-rating/rating.nix { inherit lib oarsSpec; });

          licensing-license = mkNixTest "licensing-license"
            (import ./tests/licensing/license.nix { });

          licensing-check = mkNixTest "licensing-check"
            (import ./tests/licensing/check.nix { inherit lib saltLicenses; });

          content-rating-properties = mkNixTest "content-rating-properties"
            (import ./tests/content-rating/properties.nix { inherit lib oarsSpec saltLicenses; });

          # Mapping tests
          nixpkgs-map = mkNixTest "nixpkgs-map"
            (import ./tests/nixpkgs-map.nix { inherit lib saltLicenses saltSpdx; });

          # Module tests
          module-standalone = mkNixTest "module-standalone"
            (import ./tests/module-standalone.nix { inherit lib oarsSpec saltLicenses saltSpdx; });

          # Self-license tests (eval-time claim validation)
          licensing-verify = mkNixTest "licensing-verify"
            (import ./tests/licensing/verify.nix { inherit lib; });

          # Self-license GPG verification (build-time signature check)
          self-license-verify =
            let
              selfLicense = import ./lib/licensing/verify.nix { inherit lib pkgs; };
            in
            selfLicense.mkVerifyDerivation {
              licenseFile = ./tests/licensing/fixtures/nix-license-commercial-license.json;
              signatureFile = ./tests/licensing/fixtures/nix-license-commercial-license.json.sig;
            };

          # Vendor token verification (algorithm-agnostic via openssl)
          vendor-token-verify =
            let
              selfLicense = import ./lib/licensing/verify.nix { inherit lib pkgs; };
            in
            selfLicense.mkVendorVerifyDerivation {
              licenseFile = ./tests/licensing/fixtures/vendor-package-license.json;
              signatureFile = ./tests/licensing/fixtures/vendor-package-license.json.sig;
              publicKeyFile = ./tests/licensing/fixtures/vendor-package-license.pem;
            };

          # Example reports (verifies examples evaluate correctly)
        } // (
          let
            examples = import ./examples/reports.nix { inherit lib pkgs saltLicenses saltSpdx; };
          in
          lib.mapAttrs' (name: drv: lib.nameValuePair "example-${name}" drv) examples
        ));


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
