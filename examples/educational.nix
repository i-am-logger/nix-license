# University — teaching lab with academic licenses
{
  nix-license = {
    name = "University";
    description = "Teaching lab with academic licenses";
    enable = true;
    usage = {
      type = "educational";
      commercial-use = false;
      distribution = true; # distributing course materials, lab images
      modifications = true;
      saas = false;
    };

    # Academic licenses
    licenses."matlab" = {
      licenseFile = sops.secrets.matlab-token.path;
    };
    licenses."jetbrains-idea" = {
      licenseFile = sops.secrets.jetbrains-token.path;
    };
  };
}
