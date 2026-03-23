{ lib, oarsSpec }:
{
  types = import ./types.nix { inherit lib oarsSpec; };
  rating = import ./rating.nix { inherit lib oarsSpec; };
  severity = import ./severity.nix;
}
