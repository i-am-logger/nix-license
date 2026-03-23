{ lib, oarsSpec, saltLicenses }:

{
  types = import ./types.nix { inherit lib oarsSpec; };
  contentRating = import ./content-rating.nix { inherit lib oarsSpec; };
  licenses = import ./licenses.nix { inherit lib saltLicenses; };
  licenseCheck = import ./license-check.nix { };
  token = import ./token.nix { };
}
