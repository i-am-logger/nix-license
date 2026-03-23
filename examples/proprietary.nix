# Commercial company — proprietary product, no distribution
{
  nix-license = {
    name = "Example: Commercial Company";
    description = "Proprietary product, no distribution";
    enable = true;
    enforcement = "enforce";

    usage = {
      type = "commercial";
      commercial-use = true;
      distribution = false;
      modifications = true;
      saas = false;
    };

    # Can't open-source our product → blocks GPL, AGPL
    commitments.same-license = {
      fulfilled = false;
      exceptions = [ "libfoo" ]; # except this one we already open-sourced
    };
    commitments.disclose-source.fulfilled = false;

    # Require patent grants, except for legacy code
    assurances.patent-grant = {
      required = true;
      exceptions = [ "legacy-lib" ];
    };

    # Commercial licenses
    licenses."nix-license" = {
      licenseFile = sops.secrets.nix-license-token.path;
    };
    licenses."vendor-package" = {
      licenseFile = sops.secrets.vendor-package-token.path;
    };
  };
}
