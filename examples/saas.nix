# SaaS company — Docker containers, hosting services
{
  nix-license = {
    enable = true;
    enforcement = "enforce";

    usage = {
      type = "commercial";
      commercial-use = true;
      distribution = true; # shipping containers to customers
      modifications = true;
      saas = true; # hosting services
    };

    # Can't open-source our stack
    commitments = {
      same-license.fulfilled = false;
      disclose-source.fulfilled = false;
      network-use-disclose.fulfilled = false; # blocks AGPL
    };

    # Commercial licenses
    licenses."nix-license" = {
      licenseFile = sops.secrets.nix-license-token.path;
    };
    licenses."datadog" = {
      licenseFile = sops.secrets.datadog-token.path;
    };
  };
}
