# Development

## Commands

```bash
nix develop       # Dev shell with pre-commit hooks
nix flake check   # Run all checks (formatting, linting, tests)
nix fmt           # Format all files
```

## Domain invariants

The test suite proves these properties by exhaustive evaluation over every license, every context, every combination:

- **Monotonicity** — adding a usage flag never removes a conflict (2649 × 5)
- **Totality** — every license × every context produces a definite result (2649 × 16)
- **Correctness** — restrictions block iff active, allowed-use blocks iff type excluded, commitments block iff obligation triggers and can't fulfill, assurances block iff disclaimer present and required (all 2649 × all combinations)
- **Safety** — empty usage = no conflicts (2649), no restrictions = universally allowed
- **Severity total order** — reflexive, transitive, antisymmetric, total (content policy)
- **Policy hierarchy** — restricted < moderate < unrestricted, relaxing never removes access

## Test suite

| Check | What it tests |
|-------|--------------|
| `content-rating-types` | OARS categories, severity levels, presets |
| `content-rating` | Severity ordering, policy resolution, content evaluation |
| `content-rating-severity` | Severity total order properties |
| `content-rating-policy` | Policy hierarchy, stability |
| `licensing-license` | License authorization, restriction, expiry |
| `licensing-check` | Targeted restriction, commitment, assurance checks |
| `licensing-restrictions` | 2649 × 16 restriction enforcement |
| `licensing-allowed-use` | 2649 × 6 type checks |
| `licensing-obligations` | 2649 × 16 obligation triggers |
| `licensing-commitments` | 2649 commitment blocking |
| `licensing-assurances` | 2649 × 3 assurance blocking |
| `licensing-monotonicity` | Adding flags never removes conflicts |
| `licensing-verify` | License claim validation |
| `nixpkgs-map` | 289/289 nixpkgs mapping + regression tests |
| `module-standalone` | Module config, assertions, commercial gate |
| `self-license-verify` | Build-time GPG signature verification |
| `vendor-license-verify` | Build-time openssl signature verification |
| `example-*` | Example reports evaluate correctly |
| `formatting` | treefmt (nix, shell, yaml) |
| `pre-commit` | deadnix, statix, treefmt |

## Pre-commit hooks

Installed automatically via `nix develop`:

- **deadnix** — unused code detection
- **statix** — Nix anti-pattern linting
- **treefmt** — formatting (nixpkgs-fmt, shfmt, shellcheck)
