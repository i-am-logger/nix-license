{ lib, oarsSpec, saltLicenses, saltSpdx ? { } }:

{
  contentRating = import ./content-rating { inherit lib oarsSpec; };
  licensing = import ./licensing { };
  nixpkgsMap = import ./nixpkgs-map.nix { inherit saltLicenses saltSpdx; };
  salt = import ./salt.nix { inherit lib saltLicenses; };
}
