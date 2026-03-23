# Government agency — civilian, internal use
{
  nix-license = {
    enable = true;
    enforcement = "enforce";

    usage = {
      type = "government";
      commercial-use = false;
      distribution = false;
      modifications = true;
      saas = false;
    };

    # Require patent grants for government procurement
    assurances.patent-grant.required = true;
  };
}
