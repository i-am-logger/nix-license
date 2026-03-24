# Severity level properties: total order

{ lib, oarsSpec }:

let
  cr = import ../../lib/content-rating/rating.nix { inherit lib oarsSpec; };

  assertTrue = name: value:
    if value then true
    else throw "FAIL: ${name}";

  intensities = [ "none" "mild" "moderate" "intense" ];
  pairs = xs: builtins.concatMap (a: map (b: { inherit a b; }) xs) xs;
  triples = xs: builtins.concatMap (a: builtins.concatMap (b: map (c: { inherit a b c; }) xs) xs) xs;
in
{
  severityReflexive = assertTrue "severity reflexive"
    (builtins.all (a: cr.severityAllowed a a) intensities);

  severityTransitive = assertTrue "severity transitive"
    (builtins.all ({ a, b, c }: if cr.severityAllowed a b && cr.severityAllowed b c then cr.severityAllowed a c else true) (triples intensities));

  severityTotal = assertTrue "severity total"
    (builtins.all ({ a, b }: cr.severityAllowed a b || cr.severityAllowed b a) (pairs intensities));
}
