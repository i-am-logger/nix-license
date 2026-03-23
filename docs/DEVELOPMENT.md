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
- **Policy hierarchy** — child < teen < unrestricted, relaxing never removes access

## Test suite

| Check | What it tests |
|-------|--------------|
| `lib-types` | OARS categories, severity levels, presets |
| `lib-content-rating` | Severity ordering, policy resolution, content evaluation |
| `lib-licenses` | Restrictions, commitments, assurances, allowed-use |
| `lib-token` | Token authorization, restriction, expiry |
| `lib-properties` | Domain invariants across all 2649 SALT licenses |
| `nixpkgs-map` | 289/289 nixpkgs mapping + regression tests |
| `module-standalone` | Module config, assertions, commercial gate, content policy files |
| `self-license-claims` | Token claim validation (package, commercial, expiry) |
| `self-license-verify` | Build-time GPG signature verification |
| `vendor-token-verify` | Build-time openssl signature verification |
| `formatting` | treefmt (nix, shell, yaml) |
| `pre-commit` | deadnix, statix, treefmt |

## Pre-commit hooks

Installed automatically via `nix develop`:

- **deadnix** — unused code detection
- **statix** — Nix anti-pattern linting
- **treefmt** — formatting (nixpkgs-fmt, shfmt, shellcheck)
