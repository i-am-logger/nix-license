# OpenChain ISO/IEC 5230

[OpenChain ISO/IEC 5230](https://openchainproject.org/license-compliance) is the international standard for open source license compliance programs.

## Conformance matrix

| # | OpenChain requirement | nix-license | Status |
|---|---|---|---|
| 1.1 | Written open source policy | Usage declaration — type, activities, commitments, assurances | **covered** |
| 1.2 | Staff aware of the policy | Policy is code in the system repo, reviewed in PRs | **covered** |
| 1.3 | Staff know where to find the policy | Single config file, version-controlled | **covered** |
| 1.4 | Program scope is defined | Scope = the NixOS system, every package checked | **covered** |
| 2.1 | Staff can access relevant information | SALT (2649 licenses), compliance reports | **covered** |
| 2.2 | Program is staffed and funded | | not possible |
| 3.1 | Bill of materials process | [#7](https://github.com/i-am-logger/nix-license/issues/7) — SPDX/CycloneDX export | planned |
| 3.2 | Process to handle each license | Four checks at build time (restrictions, allowed-use, commitments, assurances) | **covered** |
| 4.1 | Create compliance artifacts | Obligations tracked per-package in reports | **covered** |
| 4.2 | Archive artifacts | Nix store (immutable, content-addressed), SHA-256 integrity | **covered** |
| 5.1 | Contribution policy | | not possible |
| 6.1 | Organization conforms | | not possible |
| 6.2 | Conformance maintained over time | Runs on every build — continuous, not periodic | **covered** |
| 6.2+ | Detect license changes between updates | [#37](https://github.com/i-am-logger/nix-license/issues/37) | planned |

**9** covered · **3** planned · **3** not possible (organizational — requires humans, not software)

**Enforced by code.** Policy is code. Reviewed in PRs. Enforced on every build. No manual audits, no spreadsheets, no drift.
