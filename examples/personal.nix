# Personal user — FOSS-only with NVIDIA exception and a licensed app
{
  nix-license = {
    name = "Example: Personal";
    description = "FOSS-only with NVIDIA exception";
    enable = true;
    usage = {
      type = "personal";
      commercial-use = false;
      distribution = false;
      modifications = true;
      saas = false;
    };

    # FOSS only — block closed-source packages
    assurances.source-available = {
      required = true;
      exceptions = [ "nvidia-x11" ];
    };

    # Personal license for an app
    licenses."sublime-text" = {
      licenseFile = ./licenses/sublime-text.token;
    };
  };
}
