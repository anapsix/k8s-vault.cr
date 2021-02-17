# k8s-vault

[![GitHub release](https://img.shields.io/github/v/release/anapsix/k8s-vault.cr.svg)](https://github.com/anapsix/k8s-vault.cr/releases)

CLI utility, which makes it easy to reach K8s API via jumphost, using SSH port
forwarding.

Like [aws-vault](https://github.com/99designs/aws-vault) is a helper for AWS
related CLI tools, `k8s-vault` is a helper for CLI tools using `KUBECONFIG`.
Unlike AWS-Vault, vault here is used as a verb, synonymous to leap, jump,
spring, etc..

Original implementation of `k8s-vault` in Bash is available [here](https://gist.github.com/anapsix/b5af204162c866431cd5640aef769610).

> NOTE: Bash implementation uses slightly different config file, and old config
wont work with this implementation.
See [example config](./k8s-vault_example.yaml).

## Installation

Get latest release from [Releases](https://github.com/anapsix/k8s-vault.cr/releases) page.

Or build from source:
```sh
git clone https://github.com/anapsix/k8s-vault.cr.git
cd k8s-vault.cr
shards build
# copy ./bin/k8s-vault to some directory in your PATH
```

## Usage

Your `k8s-vault` config is expected at `~/.kube/k8s-vault-new.yaml`, but it's
location can be customized using `K8SVAULT_CONFIG` environment variable.

Likewise, `KUBECONFIG` is expected at `~/.kube/config`, but environment variable
will take precedence.

```
# Single CLI command mode
$ k8s-vault exec my-prod-context -- kubectl get nodes
(outputs results of "kubectl get nodes")
(SSH connection is terminated)

# SHELL mode
$ k8s-vault exec my-prod-context -s
(new shell is opened, with KUBECONFIG environment variable set)
$ kubectl get nodes
$ exit
(SSH connection is terminated)
```

> when launched in SHELL mode, `K8SVAULT_CONTEXT` environment variable will be
> be set to selected context

```
Usage: k8s-vault [--debug] [completion|exec <context-name>] [-s | -- <cli tool using KUBECONFIG>]

CLI Options:
  -h | --help | --usage  displays usage
  -d | --debug           enabled debug output
  example-config         outputs example config
  completion             outputs bash completion code
  exec                   executes K8s-Vault

Environment variables:
  K8SVAULT_CONFIG        path to k8s-vault config file, defaults to ~/.kube/k8s-vault.yaml
  KUBECONFIG             path to KUBECONFIG file

It works in two modes:
1. Single CLI command mode:
  - generates KUBECONFIG from exiting one, based on context name passed
  - sets up SSH Connection, Port-Forwarding random local port (or configured
    static port) to K8s API server host, selected from existing KUBECONFIG
    based on passed context name
  - executes CLI command
  - SSH Connection self-terminates after CLI command terminates
2. SHELL mode:
  - generates KUBECONFIG from exiting one, based on context name passed
  - sets up SSH Connection, Port-Forwarding random local port (or configured
    static port) to K8s API server host, selected from existing KUBECONFIG
    based on passed context name
  - executes SHELL (using $SHELL environmental variable), with KUBECONFIG
    environment variable value set to generated temp config file
  - when SHELL terminates, SSH connection is also terminated
```

## Contributing

1. Fork it (https://github.com/anapsix/k8s-vault.cr/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [anapsix](https://github.com/anapsix) (Anastas Dancha) - creator, maintainer
