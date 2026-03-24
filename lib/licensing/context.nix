# Build the full usage context including policy
# Resolves commitments and assurances per-package (exceptions applied)

{ lib }:

{
  mkUsageContext = cfg: pname: cfg.usage // {
    commitments = lib.mapAttrs
      (_: c:
        let isExcepted = builtins.elem pname c.exceptions;
        in if c.fulfilled then !isExcepted
        else isExcepted)
      cfg.commitments;
    # source-available is handled separately via SALT categories
    assurances = lib.mapAttrs
      (n: a:
        if n == "source-available" then false
        else a.required && !builtins.elem pname a.exceptions)
      cfg.assurances;
  };
}
