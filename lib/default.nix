{ lib, oarsSpec, saltLicenses }:

{
  contentRating = import ./content-rating { inherit lib oarsSpec; };
  licensing = import ./licensing { };
  salt = import ./salt.nix { inherit lib saltLicenses; };
}
