# Nonprofit organization — runs services for its mission
{
  nix-license = {
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
      licenseFile = sops.secrets.slack-token.path;
    };
  };
}
