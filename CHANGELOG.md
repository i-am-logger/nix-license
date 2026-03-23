# Changelog

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
