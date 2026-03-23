# Nonprofit organization — runs services for its mission
{
  nix-license = {
    name = "Example - Nonprofit";
    description = "Runs services for its mission";
    enable = true;
    usage = {
      type = "nonprofit";
      commercial-use = false;
      distribution = true; # distributing tools to communities
      modifications = true;
      saas = false;
    };

    # Nonprofit licenses
    licenses."slack" = {
      licenseFile = ./licenses/token.json;
    };
  };
}
