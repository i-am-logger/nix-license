_:
{
  check = import ./check.nix { };
  license = import ./license.nix { };
  context = import ./context.nix;
  constants = import ./constants.nix;
  # verify requires { lib, pkgs } — intentionally a factory function
  verify = import ./verify.nix;
}
