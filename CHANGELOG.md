# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [Unreleased]


## [0.4.3] - 2022-12-07
### Changed
- using `alpine:3.17` and `Crystal 1.6.2` to build
- making kubeconfig file created by `k8s-vault` writable


## [0.4.2] - 2021-11-29
### Changed
- using `alpine:3.15` to build


## [0.4.1] - 2021-06-10
### Changed
- using newer version of Crystal
- bumped to KCE v0.6.1

### Fixed
- log user-friendly error when requested context is not found in KUBECONFIG


## [0.4.0] - 2021-02-17
### Added
- `CHANGELOG.md`
- `K8SVAULT_CONTEXT` shell variable exported when new shell session is started,
  which can be used in `PS1` to display current `k8s-vault` context
- some spec tests

### Changed
- binary path in Docker image is not `/bin/k8s-vault`
- `make version` now updates version in example config file
- shard description updated to exclude special symbols
- crystal version set to `~> 0.36.1`
- moved argument processing into `run` method of `K8sVault` module
- moved helper methods to `K8sVault` module
- do not display error message when SSH forwarder process is no longer available

### Fixed
- formatting


## [0.3.0] - 2021-01-19
### Added
- `example-config` cli option to bash completion

### Changed
- `k8s-vault.yaml` config format updated: `clusters` renamed to `contexts`,
  since `.context[*].name` is supposed to match context name in `KUBECONFIG`
- cli argument parsing logic, and error messages output


## [0.2.2] - 2021-01-19
### Added
- cli option to output list of enabled contexts

### Changed
- bash completion no longer relies on external binaries (`jq`,`oq`)
- where `colorize` is included


## [0.2.1] - 2021-01-19
### Added
- GitHub Sponsor support

### Changed
- install only `--production` shards when building in Docker
- upgraded to `kce v0.6.0`


## [0.2.0] - 2021-01-19
### Added
- bash completion, from bash version of `k8s-vault`


## [0.1.0] - 2021-01-19
### Added
- initial implementation


[Unreleased]: https://github.com/anapsix/k8s-vault.cr/compare/v0.4.3...HEAD
[0.4.3]: https://github.com/anapsix/k8s-vault.cr/compare/v0.4.2...v0.4.3
[0.4.2]: https://github.com/anapsix/k8s-vault.cr/compare/v0.4.1...v0.4.2
[0.4.1]: https://github.com/anapsix/k8s-vault.cr/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/anapsix/k8s-vault.cr/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/anapsix/k8s-vault.cr/compare/v0.2.2...v0.3.0
[0.2.2]: https://github.com/anapsix/k8s-vault.cr/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/anapsix/k8s-vault.cr/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/anapsix/k8s-vault.cr/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/anapsix/k8s-vault.cr/tree/v0.1.0
