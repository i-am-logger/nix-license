# Open-source developer — distributes packages, copyleft OK
{
  nix-license = {
    enable = true;
    usage = {
      type = "personal";
      commercial-use = false;
      distribution = true; # publishes packages, releases, ISOs
      modifications = true;
      saas = false;
    };

    # FOSS only — with firmware exceptions
    assurances.source-available = {
      required = true;
      exceptions = [ "linux-firmware" "nvidia-x11" ];
    };
  };
}
