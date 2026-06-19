# Changelog

## [0.13.1](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.13.0...nix-license-v0.13.1) (2026-06-19)


### Documentation

* add CITATION.cff + landing-page meta description (discoverability) ([#61](https://github.com/i-am-logger/nix-license/issues/61)) ([dc383ef](https://github.com/i-am-logger/nix-license/commit/dc383ef9cc4b1dbfcf0a1e8f0929025f818059dd))

## [0.13.0](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.12.1...nix-license-v0.13.0) (2026-03-25)


### Features

* integrity hash on licenses — SHA-256 for self-verification and future chaining ([1a78d00](https://github.com/i-am-logger/nix-license/commit/1a78d00581582910bed005eb2077e40464eff33a))
* self-validating licenses — public key embedded in license file ([734dcac](https://github.com/i-am-logger/nix-license/commit/734dcacc3a4b9beebe0c32e46e938a1514f195a7))


### Bug Fixes

* actionable error messages with remediation (closes [#28](https://github.com/i-am-logger/nix-license/issues/28)) ([a8736f8](https://github.com/i-am-logger/nix-license/commit/a8736f8b77df3a75853f547c9d8a5b33c4ad10d8))
* set usage.saas = false, or add licenses."mongodb".licenseFile" ([a8736f8](https://github.com/i-am-logger/nix-license/commit/a8736f8b77df3a75853f547c9d8a5b33c4ad10d8))
* vendor license fixture — different licensee, package name, dates, new key ([92a7495](https://github.com/i-am-logger/nix-license/commit/92a74958a4fe668b0d328e6f96b310042640ae1b))


### Code Refactoring

* rename integrity→checksum in licenses, reports, and docs ([4f47f92](https://github.com/i-am-logger/nix-license/commit/4f47f924008e6c9e4d1112a3b3cc5bb618492ceb))


### Documentation

* license format, self-validation, publicKey field in COMPLIANCE.md and USAGE.md ([05dca4d](https://github.com/i-am-logger/nix-license/commit/05dca4dd9ba52225ac5208b361cbb34967a6e4dd))

## [0.12.1](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.12.0...nix-license-v0.12.1) (2026-03-24)


### Documentation

* add profile to title slide, demo subtitle, presentation polish ([3c137d4](https://github.com/i-am-logger/nix-license/commit/3c137d46379cc5e97d49099190f78fc15e404527))

## [0.12.0](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.11.8...nix-license-v0.12.0) (2026-03-24)


### Features

* presentation + reports for GitHub Pages, OSS developer in showcase ([7b13d9b](https://github.com/i-am-logger/nix-license/commit/7b13d9b8b842c115a49cdf88cbf28e9282e5fcbb))
* presentation as GitHub Pages landing + features slide + report links ([95563db](https://github.com/i-am-logger/nix-license/commit/95563dbf20b838f78693cd3b25582a13bb3e63d8))


### Documentation

* finalize presentation — 7 slides, live report embeds, full feature list ([6dffacc](https://github.com/i-am-logger/nix-license/commit/6dffacc23591d87a4add25a3a34a7205b114ea57))

## [0.11.8](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.11.7...nix-license-v0.11.8) (2026-03-24)


### Documentation

* add proven model section — MPAA, ESRB, TV, music all rate content not viewers ([fd107c0](https://github.com/i-am-logger/nix-license/commit/fd107c02560c82b1adb68e98d0ced8c264a8c491))
* honest limitation — content policy protects local, not SaaS surveillance ([3e2b3ee](https://github.com/i-am-logger/nix-license/commit/3e2b3ee33f87140821244014451357d253fbccf7))
* move limitation above proven model — honesty first ([713d48e](https://github.com/i-am-logger/nix-license/commit/713d48e85239b1cdcfecc5bde468bd556b7fd6b0))
* remove overclaim about PII in content policy ([ae0a58e](https://github.com/i-am-logger/nix-license/commit/ae0a58ec24ebe556c55705f9fc9c6b41ac503c19))

## [0.11.7](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.11.6...nix-license-v0.11.7) (2026-03-24)


### Bug Fixes

* last two teen→moderate in CONTENT-POLICY.md ([1c48450](https://github.com/i-am-logger/nix-license/commit/1c48450e83039f3792089464a39dc17230268372))


### Code Refactoring

* rename content policy presets for privacy ([d992573](https://github.com/i-am-logger/nix-license/commit/d992573a42ec6ccbe0e299684eda9fe55cd03a0d))


### Documentation

* add CONTENT-POLICY.md — OARS 1.1, privacy-first alternative to age verification ([01996f9](https://github.com/i-am-logger/nix-license/commit/01996f9c75c9515ebbcca6af6fbea84c006c95e4))
* add severity levels table before categories in CONTENT-POLICY.md ([e2b2f55](https://github.com/i-am-logger/nix-license/commit/e2b2f556db371e2c1f2c46605beafd94c7309424))
* restructure CONTENT-POLICY.md — lead with age verification problem, address PII concern ([9dc1369](https://github.com/i-am-logger/nix-license/commit/9dc13697ab8d72bac0e90b0dd1420a94da0c6458))

## [0.11.6](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.11.5...nix-license-v0.11.6) (2026-03-24)


### Bug Fixes

* BOM is planned, not covered ([1fd41a5](https://github.com/i-am-logger/nix-license/commit/1fd41a59ab158910ad81ff071d078a54159a9f49))


### Documentation

* add OPENCHAIN.md — full specification mapping with diagrams ([ccf620c](https://github.com/i-am-logger/nix-license/commit/ccf620cf7085e132bce618126205008874435d4d))
* contribution policy and conformance are planned, not impossible ([b8878f6](https://github.com/i-am-logger/nix-license/commit/b8878f680928b6a7afad1dd74711f9bffc7c2cec))
* OPENCHAIN.md — checkmarks, issue links, clean icons ([f9b84df](https://github.com/i-am-logger/nix-license/commit/f9b84df9eca7f44fcfb06147551bec52379d7799))
* OPENCHAIN.md — simple conformance matrix ([ffc33d0](https://github.com/i-am-logger/nix-license/commit/ffc33d0cecbeafdd547fce0816800beafe039569))
* rewrite OPENCHAIN.md — requirement-by-requirement mapping, enforced by code ([19b7e75](https://github.com/i-am-logger/nix-license/commit/19b7e75d9449cf7c28d20591b93808c196fa6b47))

## [0.11.5](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.11.4...nix-license-v0.11.5) (2026-03-24)


### Documentation

* rewrite COMPLIANCE.md — domain diagrams, operations flow, compliance officer audience ([374a7b0](https://github.com/i-am-logger/nix-license/commit/374a7b0f8ef385492e477614c31725455767eb6d))

## [0.11.4](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.11.3...nix-license-v0.11.4) (2026-03-24)


### Bug Fixes

* critical bugs from code review ([fb0dfe7](https://github.com/i-am-logger/nix-license/commit/fb0dfe7621d22434cd1c0133334ac76b376c67c5))
* remove all 'token' terminology — domain language only ([ae3a5ef](https://github.com/i-am-logger/nix-license/commit/ae3a5ef7b6f35150229645fcbdb697bb5c93f697))
* stale import path in tests/licensing/verify.nix ([d97357d](https://github.com/i-am-logger/nix-license/commit/d97357dc6b2305b95b7885a8aacb1defad98c65d))


### Code Refactoring

* domain naming for test fixtures ([3cb5fc8](https://github.com/i-am-logger/nix-license/commit/3cb5fc8a4a4783b2598160ae9a0c04570639feb2))
* domain terminology — rename token→license, licenses→salt ([27a4f28](https://github.com/i-am-logger/nix-license/commit/27a4f280cde5dc2286b024726def3bbd3a359945))
* extract shared context, constants, fix naming ([a9ff99b](https://github.com/i-am-logger/nix-license/commit/a9ff99b3e92993ffc57fd41c5d05cc32444af371))
* organize lib/ into domain modules ([bcfc706](https://github.com/i-am-logger/nix-license/commit/bcfc706bf06e4e4ed44414edc21656c223f87acc))
* organize tests/ to mirror lib/ structure ([65fb0a2](https://github.com/i-am-logger/nix-license/commit/65fb0a2eb27e20099ef93601af58c636e8cf6578))
* split monolithic properties.nix into SRP test files ([7c29f91](https://github.com/i-am-logger/nix-license/commit/7c29f91852bd059ea40c7540aa629d86a4c385a0))


### Documentation

* update ARCHITECTURE.md and DEVELOPMENT.md to match new structure ([0260763](https://github.com/i-am-logger/nix-license/commit/026076305d55a779ce368947a4f8774689f7a207))
* use domain terminology (license, not token) in user-facing text ([a2bb688](https://github.com/i-am-logger/nix-license/commit/a2bb688e05f28191c9412f2ce4daf1f17e862fcc))

## [0.11.3](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.11.2...nix-license-v0.11.3) (2026-03-23)


### Miscellaneous

* bump SALT to 0.5.0 (proprietary-redistributable) ([632e988](https://github.com/i-am-logger/nix-license/commit/632e9881e9b978b924ebf03a9bc2475c5ee62b8a))

## [0.11.2](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.11.1...nix-license-v0.11.2) (2026-03-23)


### Code Refactoring

* remove demos/, examples are the single source of truth ([3e0d182](https://github.com/i-am-logger/nix-license/commit/3e0d182c7bcec61a731f4e77bef214535a04efe4))

## [0.11.1](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.11.0...nix-license-v0.11.1) (2026-03-23)


### Bug Fixes

* deploy pages on every push where demo-reports succeeded ([0ae1c21](https://github.com/i-am-logger/nix-license/commit/0ae1c212c13bbbafb8f40836e9479be7a5367869))

## [0.11.0](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.10.0...nix-license-v0.11.0) (2026-03-23)


### Features

* embed full HTML report in GitHub Step Summary ([559860a](https://github.com/i-am-logger/nix-license/commit/559860a222682143a1e09dcc2b1c2f113df37ea3))
* full detail report in GitHub Step Summary with package table ([bd2dd6e](https://github.com/i-am-logger/nix-license/commit/bd2dd6e1abae07798b721d73d6b2b8251784adc4))
* name + description on all examples, report title from config ([114bebd](https://github.com/i-am-logger/nix-license/commit/114bebdeeb38dcaa4dcccf866c16eba274c0b1a8))
* nix-license.description — user sets report title ([fbb89b1](https://github.com/i-am-logger/nix-license/commit/fbb89b1c549ff72f50b4b9e1a4c06e65766f4457))
* report integrity — per-package hash + report SHA-256 ([4f120bc](https://github.com/i-am-logger/nix-license/commit/4f120bc508becbf41e3bf6bcd95b12307ff9475d))
* report metadata — version, timestamp, compliance status in footer ([784b4a5](https://github.com/i-am-logger/nix-license/commit/784b4a576b9df7d3f0e4e36c42365f96ccde5b4f))
* report title — each report shows its scenario name ([d06d9b1](https://github.com/i-am-logger/nix-license/commit/d06d9b1cdccbfc580c4e5d2f38f322031755e2b5))


### Bug Fixes

* add scenario name and verdict to GitHub Step Summary ([cce424c](https://github.com/i-am-logger/nix-license/commit/cce424c77fc35d688b2d3446e26ef6d0cddcf3b3))
* all examples use 'Example -' prefix, demos use config name/description ([a7764b6](https://github.com/i-am-logger/nix-license/commit/a7764b60c4e565b28bd0e69f7f319b13bb029f87))
* markdown Step Summary with full detail (HTML not supported) ([073371e](https://github.com/i-am-logger/nix-license/commit/073371eca485d6650c17ced9d0877bb694ca86f8))
* plain unicode icons in Step Summary (no color emoji) ([8a8546c](https://github.com/i-am-logger/nix-license/commit/8a8546c26b3e7446e3af5c4dff4e8e077b9f66ed))
* report header shows name + description on separate lines, add Example prefix ([b07564c](https://github.com/i-am-logger/nix-license/commit/b07564c7ffbf0c3e81f6a56c19dafdc8c27ae6d3))
* report layout — industry standard header, tighter spacing ([92cb337](https://github.com/i-am-logger/nix-license/commit/92cb3378e9bed323f6caaafe1eb7ce3f29164dfe))
* report layout — nix-license top-right, verdict above title, hash color ([0b08a63](https://github.com/i-am-logger/nix-license/commit/0b08a632d0e564403495766f3ece411cb14fc071))
* verdict + nix-license + datetime on right, title on left ([d75bf8f](https://github.com/i-am-logger/nix-license/commit/d75bf8fea14970138c36441794789c6be0e0e2a7))


### Code Refactoring

* action handles pages-path, CI uses it — no duplication ([a41b5d7](https://github.com/i-am-logger/nix-license/commit/a41b5d72fe38f4fe3c611ab9682e05210f792b83))


### Documentation

* add features checklist and demo report links to README ([a3f0148](https://github.com/i-am-logger/nix-license/commit/a3f0148b3793e7fded59edf71dae33520a135128))
* features table — free vs commercial, clear separation ([c1788fa](https://github.com/i-am-logger/nix-license/commit/c1788fadc4d08d4234a151393b6e6a146c16f6c7))

## [0.10.0](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.9.4...nix-license-v0.10.0) (2026-03-23)


### Features

* demo reports for all example scenarios ([604fcc4](https://github.com/i-am-logger/nix-license/commit/604fcc4a9db8f745c56e2bab4e5cf40c41dc6c9a))
* GitHub Action for license compliance reports (closes [#38](https://github.com/i-am-logger/nix-license/issues/38)) ([c73e300](https://github.com/i-am-logger/nix-license/commit/c73e3001f3fa7356ac69c70aca98b34b5ce06960))
* HTML dashboard for license compliance report ([965bf75](https://github.com/i-am-logger/nix-license/commit/965bf75f3264480035f60b155e869f83614c6fa0))
* license compliance report as JSON (closes [#27](https://github.com/i-am-logger/nix-license/issues/27)) ([3005f67](https://github.com/i-am-logger/nix-license/commit/3005f6790796300222d3b7a6e883dc9bea58b2ac))
* PASS/FAIL verdict badge in report dashboard ([18414b8](https://github.com/i-am-logger/nix-license/commit/18414b8b1c7afb253b82bd68bae805b7848663f1))
* report requires nix-license commercial token (dogfooding) ([94f5215](https://github.com/i-am-logger/nix-license/commit/94f5215d1abab2a7f78a21a99f67789f32d2ecbc))
* unicode icons in report (status, usage, verdict) ([4ee4748](https://github.com/i-am-logger/nix-license/commit/4ee4748432ba4d7c6a09c25c922ea8d25e0ea3a2))


### Bug Fixes

* report dashboard polish — icon-only badges, bigger labels ([e4dc792](https://github.com/i-am-logger/nix-license/commit/e4dc7929e165b53d086aeef7d859ea83d303a239))
* usage declaration layout — type first, yes/no badges, flex wrap ([af76b1d](https://github.com/i-am-logger/nix-license/commit/af76b1d88fa902c8c58592cb45a3c3aceb4ffd2b))
* usage layout — heading shows type, flags as labeled columns ([a6b1874](https://github.com/i-am-logger/nix-license/commit/a6b18747530c54e013fb5b0f42eb701dbc2bd78a))
* use plain unicode glyphs + CSS colors instead of emoji ([1a66e6e](https://github.com/i-am-logger/nix-license/commit/1a66e6eaf3d4e9b8b6167b0f7438b484c31f4c60))

## [0.9.4](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.9.3...nix-license-v0.9.4) (2026-03-23)


### Code Refactoring

* extract shared options to lib/options.nix (closes [#30](https://github.com/i-am-logger/nix-license/issues/30)) ([3b9045a](https://github.com/i-am-logger/nix-license/commit/3b9045affd113965c6b8148d06abf8f5bcddf3da))

## [0.9.3](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.9.2...nix-license-v0.9.3) (2026-03-23)


### Bug Fixes

* mynixos module includes default module (closes [#31](https://github.com/i-am-logger/nix-license/issues/31)) ([868160c](https://github.com/i-am-logger/nix-license/commit/868160c6d09be1327494500c98edda9b6661c602))

## [0.9.2](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.9.1...nix-license-v0.9.2) (2026-03-23)


### Bug Fixes

* check ALL packages, not just unfree (closes [#25](https://github.com/i-am-logger/nix-license/issues/25)) ([81957b9](https://github.com/i-am-logger/nix-license/commit/81957b92dfffa52e956d83997b33dba30de1f1e0))

## [0.9.1](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.9.0...nix-license-v0.9.1) (2026-03-23)


### Bug Fixes

* embedded vendor keys cannot be overridden (source of trust) ([3b97a5f](https://github.com/i-am-logger/nix-license/commit/3b97a5f1a85fbcba039e176da560a430c14d878d))
* enforce mode error messages, naming, vendor key priority ([6dae546](https://github.com/i-am-logger/nix-license/commit/6dae5469a4331b2a21d42b94af50471f4a9bf397))
* minor review findings ([b02b439](https://github.com/i-am-logger/nix-license/commit/b02b439beee29638fb824aadd439915206da8501))

## [0.9.0](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.8.1...nix-license-v0.9.0) (2026-03-23)


### Features

* license install option + vendor key verification ([4a92e05](https://github.com/i-am-logger/nix-license/commit/4a92e056aadb3746d928330fb1d88e01de68e99b))


### Code Refactoring

* assurances as { required; exceptions; } submodules ([97d3ee2](https://github.com/i-am-logger/nix-license/commit/97d3ee263909c4e3427898d6327a11fbe97d5757))

## [0.8.1](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.8.0...nix-license-v0.8.1) (2026-03-23)


### Code Refactoring

* assurances as { required; exceptions; } submodules ([764de9e](https://github.com/i-am-logger/nix-license/commit/764de9e072b398dfac19c993f6a3f8e5a65a64a9))

## [0.8.0](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.7.0...nix-license-v0.8.0) (2026-03-23)


### Features

* add source-available assurance — replaces allowUnfree for FOSS users ([c73f4a9](https://github.com/i-am-logger/nix-license/commit/c73f4a9cc8d5436d2f3077a770661b9efd8b9617))


### Code Refactoring

* assurances as { required; exceptions; } submodules ([d9e0d8b](https://github.com/i-am-logger/nix-license/commit/d9e0d8b61f474bcad96edaea0de9cbe31440c5c0))

## [0.7.0](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.6.5...nix-license-v0.7.0) (2026-03-23)


### Features

* add source-available assurance — replaces allowUnfree for FOSS users ([a4de1e0](https://github.com/i-am-logger/nix-license/commit/a4de1e08fc623abc48f395dc66996302cc60e6d7))


### Documentation

* update readme.md, workflow name ([d8fb8da](https://github.com/i-am-logger/nix-license/commit/d8fb8daca9bd073893ceeed37133d6bb3db04fa1))

## [0.6.5](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.6.4...nix-license-v0.6.5) (2026-03-23)


### Bug Fixes

* remove tokenVerification.enable — requireTokens is sufficient ([8ffcc43](https://github.com/i-am-logger/nix-license/commit/8ffcc43ad6fdcf043351e50a6c7fb007744e3dab))


### Code Refactoring

* unified license API — remove requireTokens and license.* ([feb8c40](https://github.com/i-am-logger/nix-license/commit/feb8c405a037cdba45bcdc0ab761ef6bcc5e5ada))


### Documentation

* add DEVELOPMENT.md with domain invariants and test suite ([f528d55](https://github.com/i-am-logger/nix-license/commit/f528d5530e4eb671cc60347b4ab5a772fae03f1b))
* add DEVELOPMENT.md with domain invariants and test suite ([ed07dda](https://github.com/i-am-logger/nix-license/commit/ed07dda968547609d37128aa9c21395a7ab2d23a))
* add domain model and data flow diagrams (Mermaid) ([fed2771](https://github.com/i-am-logger/nix-license/commit/fed2771bb394570fbabba8b38f13311f9cc16f07))
* add license.tokenFile to commercial example in README ([78f02b5](https://github.com/i-am-logger/nix-license/commit/78f02b58dd473eabe721ce5638211d8bda7a30b8))
* add per-package vendor license setup to USAGE.md and README ([3e593fa](https://github.com/i-am-logger/nix-license/commit/3e593fa688d593708aac39220ac38210e9dc32af))
* add testing section to README ([af9da45](https://github.com/i-am-logger/nix-license/commit/af9da45471fbadbc1dfed127c0e3d2801e93d283))
* clarify what the 200k checks actually test ([e811279](https://github.com/i-am-logger/nix-license/commit/e81127941d355a9710c2fb2ed7e02543dc7f3894))
* rename vendor-sdk to vendor-package in examples ([356f2dd](https://github.com/i-am-logger/nix-license/commit/356f2dd0b5974503eec4c58c11ab60400cc21e6d))

## [0.6.4](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.6.3...nix-license-v0.6.4) (2026-03-23)


### Documentation

* add CC BY-NC-SA 4.0 license ([a01cb12](https://github.com/i-am-logger/nix-license/commit/a01cb128c5719878c590b54d9c9e96535b2c1497))
* match mynixos badge style ([bdba51d](https://github.com/i-am-logger/nix-license/commit/bdba51d1f314ef63cfa0c3d06f5edcd503810c40))

## [0.6.3](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.6.2...nix-license-v0.6.3) (2026-03-23)


### Bug Fixes

* proper file permissions on content policy files ([77317c8](https://github.com/i-am-logger/nix-license/commit/77317c88c44a99af994e2c5196a34bae53e7ee67))
* system content policy root:root 0644 (apps need to read it) ([564d8a6](https://github.com/i-am-logger/nix-license/commit/564d8a61ce6ff98583610fab3a6c8485c782a506))

## [0.6.2](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.6.1...nix-license-v0.6.2) (2026-03-23)


### Documentation

* restructure README, move domain model and OpenChain to docs ([d8f3443](https://github.com/i-am-logger/nix-license/commit/d8f3443095e96da30743a88b0f2013026509eac1))
* rewrite README — show code first, drop marketing ([703d556](https://github.com/i-am-logger/nix-license/commit/703d556495d89dc237a5295967067f05b302b17d))

## [0.6.1](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.6.0...nix-license-v0.6.1) (2026-03-23)


### Bug Fixes

* address all 13 review findings ([e5826d7](https://github.com/i-am-logger/nix-license/commit/e5826d737c9a2e87fe34431107d538cdf8c7556c))

## [0.6.0](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.5.2...nix-license-v0.6.0) (2026-03-22)


### Features

* vendor token verification with algorithm-agnostic signatures ([efd4e82](https://github.com/i-am-logger/nix-license/commit/efd4e82c5ffdb02f7f707a49cd7554823ce83f83))

## [0.5.2](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.5.1...nix-license-v0.5.2) (2026-03-22)


### Miscellaneous

* update SALT flake.lock + add status to RFCs ([b30024b](https://github.com/i-am-logger/nix-license/commit/b30024b57c0d730db4a358c76c4b7af02afb2634))

## [0.5.1](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.5.0...nix-license-v0.5.1) (2026-03-22)


### Documentation

* check off cryptographic license tokens in features ([4750131](https://github.com/i-am-logger/nix-license/commit/47501311512b22f6237ecb44b5505cb4e1ad8cf2))

## [0.5.0](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.4.0...nix-license-v0.5.0) (2026-03-22)


### Features

* commercial gate with YubiKey public keys ([91c4721](https://github.com/i-am-logger/nix-license/commit/91c472133f6c95c28ca46f84dc892a66653147ba))
* end-to-end token verification with YubiKey-signed test token ([c8440d6](https://github.com/i-am-logger/nix-license/commit/c8440d6ed18caee983834afee5035ce385d629b2))

## [0.4.0](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.3.1...nix-license-v0.4.0) (2026-03-22)


### Features

* per-package license enforcement with full behavioral verification ([32f9d60](https://github.com/i-am-logger/nix-license/commit/32f9d6039fc572c57db4603e59512c957faf6942))


### Documentation

* clarify SALT vocabulary is independent, OSADL is a reference ([e7272b4](https://github.com/i-am-logger/nix-license/commit/e7272b45520a05cf5cc967a326c193d769b0270e))

## [0.3.1](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.3.0...nix-license-v0.3.1) (2026-03-22)


### Code Refactoring

* remove allowClosedSource, set allowUnfree=true ([da7375d](https://github.com/i-am-logger/nix-license/commit/da7375d83fa2c01f54980e6ed878db7b28384add))


### Documentation

* lead with license terms (restrictions, allowed-use, obligations, disclaimers) ([74ebc62](https://github.com/i-am-logger/nix-license/commit/74ebc6262aea93e6249839d8660ed46e693e6746))
* README explains terminology for compliance audience ([4581562](https://github.com/i-am-logger/nix-license/commit/458156204b9bdd117982932a40202672652440c8))
* reorder docs — compliance first ([260a731](https://github.com/i-am-logger/nix-license/commit/260a731c19ecc70cffaa56142ff65a7047dd6bc3))
* rewrite README for compliance audience ([79d36ea](https://github.com/i-am-logger/nix-license/commit/79d36eabb9fe43039038df574adc2fd1f1a27dba))
* rewrite README for compliance audience, add USAGE.md ([4016d08](https://github.com/i-am-logger/nix-license/commit/4016d08e0f0cdaad05b445099910ab9351cc1e9f))
* simplify documentation links ([dc42dbb](https://github.com/i-am-logger/nix-license/commit/dc42dbb7bba381fb44abc170d8894cad6fa413a2))
* simplify README — no marketing ([85db4c6](https://github.com/i-am-logger/nix-license/commit/85db4c65ac872881a81f94c2ebc5878b80851f6f))
* trim README — state what it does, nothing more ([4cf8079](https://github.com/i-am-logger/nix-license/commit/4cf807959541300658b29d68d4d1b7851047e698))
* update README, ARCHITECTURE, COMPLIANCE for current state ([29e7ac7](https://github.com/i-am-logger/nix-license/commit/29e7ac716742e738fb9ba1a86c23839eb92c5d50))

## [0.3.0](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.2.2...nix-license-v0.3.0) (2026-03-22)


### Features

* add usage consistency assertions ([bb65836](https://github.com/i-am-logger/nix-license/commit/bb6583688d5a53b6d8a33f44290ab12841943da1))
* add usage.type for allowed-use checks ([6b49a6c](https://github.com/i-am-logger/nix-license/commit/6b49a6c99fb0d0d06cf643d9c64e7592ef54925b))

## [0.2.2](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.2.1...nix-license-v0.2.2) (2026-03-22)


### Code Refactoring

* simplify usage to match SALT restriction keys ([d0ceabf](https://github.com/i-am-logger/nix-license/commit/d0ceabfdbb93fd238072dba97ece0989a59151c0))

## [0.2.1](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.2.0...nix-license-v0.2.1) (2026-03-22)


### Code Refactoring

* switch to SALT as license data source ([df0847f](https://github.com/i-am-logger/nix-license/commit/df0847f6f7b2020f269f57b0732e4a989eb872e9))

## [0.2.0](https://github.com/i-am-logger/nix-license/compare/nix-license-v0.1.0...nix-license-v0.2.0) (2026-03-21)


### Features

* initial scaffolding with RFCs, flake, CI, and tooling ([01df6df](https://github.com/i-am-logger/nix-license/commit/01df6df24616b1e5990666df25781393b2cc0aed))

## 0.1.0 (unreleased)

### Documentation

* Initial RFCs for usage-context license model, cryptographic license tokens, and content policy model
