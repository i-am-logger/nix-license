# OpenChain ISO/IEC 5230

[OpenChain ISO/IEC 5230](https://openchainproject.org/license-compliance) is the international standard for open source license compliance programs.

## Conformance matrix

| # | OpenChain requirement | nix-license | Status |
|---|---|---|---|
| 1.1 | Written open source policy | `nix-license.usage` + `commitments` + `assurances` | ✔ |
| 1.2 | Staff aware of the policy | Policy is code in the system repo, reviewed in PRs | ✔ |
| 1.3 | Staff know where to find the policy | Single config file, version-controlled | ✔ |
| 1.4 | Program scope is defined | Scope = the NixOS system, every package checked | ✔ |
| 2.1 | Staff can access relevant information | [SALT](https://github.com/i-am-logger/salt) (2649 licenses) + [compliance reports](https://i-am-logger.github.io/nix-license/) | ✔ |
| 2.2 | Program is staffed and funded | | — |
| 3.1 | Bill of materials process | [#7](https://github.com/i-am-logger/nix-license/issues/7) — SPDX/CycloneDX export | ○ |
| 3.2 | Process to handle each license | `lib/licensing/check.nix` — restrictions, allowed-use, commitments, assurances | ✔ |
| 4.1 | Create compliance artifacts | Obligations tracked per-package in reports | ✔ |
| 4.2 | Archive artifacts | Nix store (immutable, content-addressed), SHA-256 integrity | ✔ |
| 5.1 | Contribution policy | [#48](https://github.com/i-am-logger/nix-license/issues/48) — contribution rules as config | ○ |
| 6.1 | Organization conforms | [#49](https://github.com/i-am-logger/nix-license/issues/49) — conformance report with checklist | ○ |
| 6.2 | Conformance maintained over time | Runs on every build — continuous, not periodic | ✔ |
| 6.2+ | Detect license changes between updates | [#37](https://github.com/i-am-logger/nix-license/issues/37) | ○ |

✔ **9** covered · ○ **4** planned · — **1** organizational (2.2 staffing)

**Enforced by code.** Policy is code. Reviewed in PRs. Enforced on every build. No manual audits, no spreadsheets, no drift.
