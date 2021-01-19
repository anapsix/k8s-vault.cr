require "colorize"
require "kce"
require "./k8s-vault/*"

module K8sVault

  include K8sVault::Constants

  record Config,
    config_path : String,
    kubeconfig_path : String,
    kubeconfig : String,
    kubecontext : String,
    ssh_jump_host : String,
    remote_host : String,
    remote_port : String,
    local_port : String,
    k8s_api_timeout : String

  def self.config(kubecontext : String, config_path : String? = nil, kubeconfig_path : String? = nil)
    config_path ||= K8sVault::K8SVAULT_CONFIG
    kubeconfig_path ||= K8sVault::KUBECONFIG

    config = K8sVault::ConfigReader.config(config_path)
    context_config = config.clusters.select {|c| c.name == kubecontext}
    if context_config.empty?
      raise K8sVault::UnconfiguredContextError.new(kubecontext: kubecontext)
    end
    context_config = context_config.first
    if context_config.enabled != true
      raise K8sVault::DisabledContextError.new(kubecontext: kubecontext)
    end
    ssh_jump_host = context_config.ssh_jump_host

    kubeconfig = KCE.config(kubecontext: kubecontext, kubeconfig: kubeconfig_path)
    cluster_server = kubeconfig.clusters.first.cluster.server.to_s
    remote_proto = cluster_server.split(/https?:\/\//).first?.to_s
    remote_proto = remote_proto.empty? ? "https" : remote_proto
    remote_host, remote_port = cluster_server.split(/https?:\/\//).last.split(":")

    local_port  = if config.ssh_forwarding_port.random == true
                    Random.rand(K8sVault::RANDOM_PORT_RANGE) + K8sVault::RANDOM_PORT_OFFSET
                  else
                    config.ssh_forwarding_port.static
                  end

    # update config with values for SSH forwarding
    kubeconfig.clusters.first.cluster.certificate_authority_data = nil
    kubeconfig.clusters.first.cluster.insecure_skip_tls_verify = true
    kubeconfig.clusters.first.cluster.server = "#{remote_proto}://127.0.0.1:#{local_port}"

    Config.new(
      config_path: config_path.to_s,
      kubeconfig_path: kubeconfig_path.to_s,
      kubeconfig: kubeconfig.to_yaml,
      kubecontext: kubecontext.to_s,
      ssh_jump_host: ssh_jump_host.to_s,
      remote_host: remote_host.to_s,
      remote_port: remote_port.to_s,
      local_port: local_port.to_s,
      k8s_api_timeout: config.k8s_api_timeout.to_s
    )
  end

  def self.example_config
    puts {{ read_file("#{__DIR__}/../k8s-vault_example.yaml") }}
  end

  def self.completion
    puts {{ read_file("#{__DIR__}/../k8s-vault-completion.bash") }}
  end

  def self.usage
    puts <<-USAGE
    k8s-vault makes it easy to reach K8s API via jumphost, using SSH port forwarding.

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

    Examples:
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
    USAGE
  end

  # def self.run(options)

  #   kubecontext = nil
  #   spawn_shell = false

  #   while options.size > 0
  #     case options.first
  #     when "-h","--help","--usage"
  #       self.usage
  #       exit 0
  #     when "-d", "--debug"
  #       @@debug = true
  #       options.shift
  #     when "exec"
  #       options.shift
  #       kubecontext = options.first
  #       options.shift
  #       if options.size > 0 && options.first == "-s"
  #         spawn_shell = true
  #         options.shift
  #         break
  #       end
  #     when "--"
  #       options.shift
  #       break
  #     else
  #       raise K8sVault::UnexpectedOptionError.new(option: options.first.to_s)
  #     end
  #   end

  #   config = K8sVault.config(kubecontext: kubecontext)
  #   temp_config = File.tempfile("k8s-vault-kubeconfig.yaml")
  # end
end
