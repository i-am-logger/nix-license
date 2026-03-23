# Research lab — academic research, publishes results
{
  nix-license = {
    name = "Research Lab";
    description = "Academic research, publishes results";
    enable = true;
    usage = {
      type = "research";
      commercial-use = false;
      distribution = true; # publishing reproducible builds, datasets
      modifications = true;
      saas = false;
    };

    # FOSS only — reproducibility requires source access
    assurances.source-available = {
      required = true;
      exceptions = [ "cuda" "nvidia-x11" ]; # GPU computing needs
    };

    # Research licenses
    licenses."mathematica" = {
      licenseFile = sops.secrets.mathematica-token.path;
    };
    licenses."matlab" = {
      licenseFile = sops.secrets.matlab-token.path;
    };
  };
}
