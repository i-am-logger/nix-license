# University — teaching lab with academic licenses
{
  nix-license = {
    name = "Example - University";
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
      licenseFile = ./licenses/token.json;
    };
    licenses."jetbrains-idea" = {
      licenseFile = ./licenses/token.json;
    };
  };
}
