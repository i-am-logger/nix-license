{ lib, oarsSpec, saltLicenses }:

{
  types = import ./types.nix { inherit lib oarsSpec; };
  contentRating = import ./content-rating.nix { inherit lib oarsSpec; };
  licenses = import ./salt.nix { inherit lib saltLicenses; };
  licenseCheck = import ./license-check.nix { };
  license = import ./license.nix { };
}
