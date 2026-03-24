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
  em { color: #8b949e; }
---

# nix-license

**Automated software license compliance for the AI era**

*A scan tells you what's wrong. A build gate prevents it.*

<div style="position:absolute;bottom:80px;display:flex;align-items:center;gap:1em">
<img src="https://github.com/i-am-logger.png" style="width:60px;border-radius:50%;border:2px solid #30363d">
<div>
<div style="font-weight:bold;color:#f0f6fc">Logger</div>
<div style="color:#8b949e;font-size:0.8em">i-am-logger · nix-license.dev</div>
</div>
</div>

---

# The problem

**AI is generating code faster than humans can audit it.**

A developer using Copilot, Claude, or Cursor can introduce 50 dependencies in an afternoon. No compliance team can review that manually.

Compliance moved from manual to automated in AML because transaction volume made manual review impossible. **License compliance is at the same inflection point.**

---

# Features — free

| Feature | |
|---------|:---:|
| License enforcement — restrictions, obligations, allowed-use | ✔ |
| 2649 classified licenses (SALT) | ✔ |
| Full nixpkgs coverage (289 licenses mapped) | ✔ |
| Commitments — declare what you can fulfill | ✔ |
| Assurances — require patent grants, source, warranty | ✔ |
| Content policy — per-user entitlements (OARS 1.1) | ✔ |
| 200,000+ compliance checks per build | ✔ |

---

# Features — commercial + planned

| Feature | Status |
|---------|:------:|
| Cryptographic license verification (GPG + openssl) | ✔ |
| Compliance reports — JSON + HTML dashboard | ✔ |
| GitHub Action — CI/CD integration | ✔ |
| SBOM generation (SPDX/CycloneDX) | planned |
| OpenChain ISO/IEC 5230 conformance | planned |
| Audit trail | planned |
| License change detection | planned |

---

# How you use it

**Who are you?** → `commercial` *(or personal, educational, research, government, nonprofit)*

**Commercial use?** → `true`

**Distributing software?** → `true`

**Running SaaS?** → `false`

**Can you open-source your product?** → `false` ← blocks GPL, AGPL

**Require patent grants?** → `true` ← blocks licenses without patent rights

The build **won't succeed** if any package violates these declarations.

---

# What you get

*Demo — live reports generated on every release from nix-license examples*

<div style="display:flex;gap:1%;height:82%">
<div style="flex:1;overflow:hidden;border:1px solid #30363d;border-radius:6px">
<iframe src="personal/index.html" style="width:400%;height:400%;border:none;transform:scale(0.25);transform-origin:0 0;background:#0d1117"></iframe>
</div>
<div style="flex:1;overflow:hidden;border:1px solid #30363d;border-radius:6px">
<iframe src="saas/index.html" style="width:400%;height:400%;border:none;transform:scale(0.25);transform-origin:0 0;background:#0d1117"></iframe>
</div>
<div style="flex:1;overflow:hidden;border:1px solid #30363d;border-radius:6px">
<iframe src="oss-developer/index.html" style="width:400%;height:400%;border:none;transform:scale(0.25);transform-origin:0 0;background:#0d1117"></iframe>
</div>
</div>

---

# Thank you

<div style="display:flex;align-items:center;gap:1.5em;margin:2em 0">
<img src="https://github.com/i-am-logger.png" style="width:120px;border-radius:50%;border:3px solid #30363d">
<div>
<div style="font-size:1.4em;font-weight:bold;color:#f0f6fc">Logger</div>
<div style="color:#8b949e;font-size:1.1em">i-am-logger</div>
</div>
</div>

[nix-license.dev](https://nix-license.dev)

[github.com/i-am-logger/nix-license](https://github.com/i-am-logger/nix-license)

[github.com/i-am-logger/salt](https://github.com/i-am-logger/salt) — 2649 classified licenses
