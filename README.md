[![NixOS](https://img.shields.io/badge/NixOS-5277C3?logo=nixos&logoColor=white)](https://nixos.org)
[![CI and Release](https://github.com/i-am-logger/nix-license/actions/workflows/ci-and-release.yml/badge.svg)](https://github.com/i-am-logger/nix-license/actions/workflows/ci-and-release.yml)

# nix-license

NixOS license compliance -- RFCs and a NixOS module for fine-grained software licensing control.

## RFCs

- [Usage-Context-Based License Model](docs/rfc-usage-context-license-model.md) -- Replace `allowUnfree` with separate source-availability and usage-context axes
- [Cryptographic License Tokens](docs/rfc-cryptographic-license-tokens.md) -- Offline-verifiable license proof for Nix builds
- [Content Policy Model](docs/rfc-content-policy-model.md) -- Content category entitlements as a third licensing axis

## Status

RFC stage. The NixOS module is not yet implemented.

## Development

```bash
nix develop       # Enter dev shell with pre-commit hooks
nix flake check   # Run all checks
nix fmt            # Format all files
```
