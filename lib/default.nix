{ lib, oarsSpec, saltLicenses }:

{
  types = import ./content-rating/types.nix { inherit lib oarsSpec; };
  contentRating = import ./content-rating/rating.nix { inherit lib oarsSpec; };
  licenses = import ./salt.nix { inherit lib saltLicenses; };
  licenseCheck = import ./licensing/check.nix { };
  license = import ./licensing/license.nix { };
}
