---
marp: true
theme: default
paginate: true
backgroundColor: #0d1117
color: #c9d1d9
style: |
  section {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
    font-size: 28px;
  }
  h1 { color: #58a6ff; font-size: 1.6em; }
  h2 { color: #c9d1d9; font-size: 1.3em; }
  a { color: #58a6ff; }
  table { font-size: 1em; width: 100%; border-collapse: collapse; background: transparent; }
  th { color: #58a6ff; font-size: 0.9em; border-bottom: 2px solid #30363d; background: #161b22; padding: 0.5em 0.7em; }
  td { color: #e6edf3; padding: 0.5em 0.7em; border-bottom: 1px solid #21262d; background: #0d1117; }
  tr:nth-child(even) td { background: #161b22; }
  code { background: #161b22; color: #e6edf3; padding: 0.1em 0.4em; border-radius: 4px; }
  pre { background: #161b22 !important; border: 1px solid #30363d; border-radius: 6px; padding: 1em; }
  pre code { background: transparent !important; }
  strong { color: #f0f6fc; }
  blockquote { border-left: 4px solid #58a6ff; padding-left: 1em; color: #8b949e; font-size: 1.1em; }
---

# nix-license

**Automated license compliance for the AI era**

Ido Samuelson
nix-license.dev

---

# The problem

**AI is generating code faster than humans can audit it.**

A developer using Copilot, Claude, or Cursor can introduce 50 dependencies in an afternoon.

No compliance team can review that manually.

---

# What is a software license?

Every piece of software comes with a legal contract — the license.

**Restrictions** — what you can't do
*No commercial use. No SaaS. No redistribution.*

**Obligations** — what you must do
*Disclose source code. Use the same license. Include copyright.*

**Disclaimers** — what's not guaranteed
*No warranty. No patent rights. No liability coverage.*

Violating a license = **legal liability**.

---

# The risk is real

| License | Risk |
|---------|------|
| GPL in a proprietary product | Forced source disclosure or lawsuit |
| AGPL in a SaaS platform | Must open-source entire service stack |
| CC-BY-NC in commercial use | License violation, damages |
| No license declared | Unknown legal exposure |

**Most companies don't know what licenses they're using.**

---

# How compliance works today

**Best case:** FOSSA, Snyk, or Black Duck in CI/CD — scans code, produces reports.

But a scan is not a build:

| SCA scan (FOSSA/Snyk) | nix-license |
|---|---|
| Scans after code is written | Checks before code is built |
| Report says "you have a problem" | Build says "you can't ship this" |
| Developer can ignore the report | Developer can't ignore a failed build |
| Runs on source code | Runs on the actual build closure |
| Misses transitive dependencies | Checks every dependency (Nix knows the full tree) |

**A scan tells you what's wrong. A build gate prevents it.**

---

# The same shift compliance already made

AML moved from manual to automated because transaction volume made manual review impossible.

**License compliance is at the same inflection point.**

**AI-generated code is the volume accelerator.**

---

# What is SALT?

**Software And License Taxonomy** — 2649 software licenses classified.

Every license is analyzed for:

| Term | What it answers |
|------|----------------|
| **Grants** | What can you do? |
| **Restrictions** | What can't you do? |
| **Obligations** | What must you do? |
| **Disclaimers** | What's not guaranteed? |

Like a **sanctions list** — but for software licenses.

Open source: [github.com/i-am-logger/salt](https://github.com/i-am-logger/salt)

---

# What is Nix?

A **declarative build system** — you describe what you want, the system produces it reproducibly.

| | Traditional Docker | Nix-built Docker |
|---|---|---|
| Dependencies | `apt install` — unknown transitive deps | Exact closure — every dependency tracked |
| Reproducibility | Depends on build date, mirror state | Same input = same output, always |
| Image size | Alpine ~50-80MB | Only what's needed ~15-20MB |
| License visibility | Scan after build, hope you catch it | Every package mapped to SALT |

**Nix knows every file in the build, where it came from, and what license it's under.**

---

# How nix-license works — declare your usage

The organization answers four questions:

**Who are you?** → `commercial` *(or personal, educational, research, government, nonprofit)*

**Commercial use?** → `true`

**Distributing software?** → `true`

**Running SaaS?** → `false`

All fields required. No implicit assumptions. No defaults.

---

# How nix-license works — four compliance checks

Every package is checked. All must pass.

| License says | You declared | Blocks when |
|---|---|---|
| **Restrictions** — what's prohibited | Activities you do | You do a restricted activity |
| **Allowed-use** — who can use it | Your type | Your type not in the list |
| **Obligations** — what you must do | Commitments you can fulfill | You can't fulfill an obligation |
| **Disclaimers** — what's not guaranteed | Assurances you require | License disclaims what you need |

---

# How nix-license works

## 3. Non-compliant = build fails

```
nix-license: BLOCKED: mongodb — restriction: saas
nix-license: BLOCKED: elastic — restriction: saas
nix-license: BLOCKED: gcc — commitment: same-license
```

**The software doesn't build if you're not compliant.**

Not a report you read later. Not a scan you run quarterly.
The build **won't succeed**.

---

# The compliance report

JSON + HTML dashboard per system, per build.

![bg right:55% fit](https://i-am-logger.github.io/nix-license/saas/index.html)

- **PASS / FAIL** verdict
- Every package, version, license, status
- Searchable, filterable
- SHA-256 integrity hash
- Per-system, per-build

**Live examples:** [i-am-logger.github.io/nix-license](https://i-am-logger.github.io/nix-license/)

---

# OpenChain ISO/IEC 5230

The international standard for open source compliance programs.

| # | Requirement | nix-license | Status |
|---|---|---|---|
| 1.1 | Written policy | Usage declaration in config | ✔ |
| 1.2-1.4 | Awareness, scope | Policy is code, version-controlled | ✔ |
| 3.1 | Bill of materials | SBOM export | planned |
| 3.2 | License handling | Four checks at build time | ✔ |
| 4.1-4.2 | Artifacts, archival | Reports + Nix store (immutable) | ✔ |
| 5.1 | Contribution policy | Approved license list | planned |
| 6.2 | Maintained over time | Runs on every build | ✔ |

**9 covered · 4 planned · 1 organizational**

---

# Enforced by code

| Traditional compliance | nix-license |
|---|---|
| Policy in a document | Policy in code |
| Reviewed annually | Reviewed in every PR |
| Enforced by humans | Enforced by the build system |
| Drift between policy and practice | Zero drift — policy IS the build |
| Quarterly audits | Continuous — every build |

---

# Content policy

Beyond licenses — **what content is each user entitled to?**

The proven model: MPAA rates movies, ESRB rates games, OARS rates software.
Rate the **content**, not the **viewer**. No birth dates. No PII.

| | Age verification | Content policy |
|---|---|---|
| Privacy | Requires PII (birth date, ID) | No PII — admin sets policy |
| Enforcement | Each app decides | System-wide, consistent |
| Granularity | Binary (old enough or not) | 22 categories × 4 severity levels |

**California, Colorado, New York are pushing age verification.**
**Content policy is the alternative.**

---

# Vision

## Today
Policy declared → Build-time enforcement → Compliance reports

## Near term
- SBOM generation (SPDX/CycloneDX)
- License change detection between updates
- Contribution policy (outbound compliance)
- OpenChain conformance report

## Future
- AI-powered content filtering at runtime
- Hardware content enforcement (FPGA)
- Continuous compliance across fleet

---

# Features

| Feature | Free | Commercial |
|---------|:----:|:----------:|
| License enforcement (restrictions, allowed-use, obligations) | ✔ | ✔ |
| 2649 classified licenses (SALT) | ✔ | ✔ |
| Full nixpkgs coverage (289 licenses) | ✔ | ✔ |
| Commitments (declare what you can fulfill) | ✔ | ✔ |
| Assurances (require patent grants, source, warranty) | ✔ | ✔ |
| Content policy (OARS 1.1 per-user entitlements) | ✔ | ✔ |
| 200,000+ compliance checks per build | ✔ | ✔ |
| Cryptographic license verification | | ✔ |
| Compliance reports (JSON + HTML) | | ✔ |
| GitHub Action (CI/CD) | | ✔ |
| SBOM generation | | planned |
| OpenChain conformance | | planned |
| License change detection | | planned |

---

# Live example reports

**[Personal — FOSS-only with NVIDIA exception](https://i-am-logger.github.io/nix-license/personal/)**
All 17 packages allowed. NVIDIA whitelisted via assurance exception.

**[SaaS — Docker containers](https://i-am-logger.github.io/nix-license/saas/)**
10 of 17 packages blocked. GPL blocked by commitment (can't disclose source).

**[Proprietary — commercial product](https://i-am-logger.github.io/nix-license/proprietary/)**
Copyleft blocked with exceptions. Patent grants required.

---

# The bottom line

**Software license compliance has the same problem AML had 20 years ago — too much volume for manual review.**

nix-license automates it:
- **2649 licenses** classified in SALT
- **Every package** checked at build time
- **Policy as code** — no drift, no spreadsheets
- **Audit-ready** reports and artifacts
- **OpenChain** conformance path

**The build won't succeed if you're not compliant.**

---

# Thank you

**Ido Samuelson**

[github.com/i-am-logger/nix-license](https://github.com/i-am-logger/nix-license)
[github.com/i-am-logger/salt](https://github.com/i-am-logger/salt)

Live reports: [i-am-logger.github.io/nix-license](https://i-am-logger.github.io/nix-license/)
