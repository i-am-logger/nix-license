_:
{
  check = import ./check.nix { };
  license = import ./license.nix { };
  verify = import ./verify.nix;
}
