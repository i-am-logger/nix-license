# SaaS company — Docker containers, hosting services
{
  nix-license = {
    name = "Example - SaaS Company";
    description = "Docker containers, hosting services";
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
      licenseFile = ./licenses/token.json;
    };
    licenses."datadog" = {
      licenseFile = ./licenses/token.json;
    };
  };
}
