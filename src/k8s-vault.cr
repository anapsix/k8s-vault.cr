require "kce"
require "socket"
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
    context_config = config.contexts.select { |c| c.name == kubecontext }
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

    local_port = if config.ssh_forwarding_port.random == true
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

  # Waits for connection to TCP port of the server for the duration of timeout
  #
  # Returns `true` if connection is successful, otherwise `false`
  #
  # Example:
  # ```
  # unless wait_for_connection(host: "localhost", port: 8080, timeout: 10, sleep_cycle: 1)
  #   STDERR.puts "failed to establish connection within 10 seconds"
  #   exit 1
  # end
  # ```
  def self.wait_for_connection(host : String = "localhost", port : Int32 = 80, timeout : Int32 = 5, sleep_cycle : Float32 = 0.25) : Bool
    start_time = Time.monotonic
    client = TCPSocket.new
    loop do
      break if (Time.monotonic - start_time) > timeout.seconds
      begin
        client = TCPSocket.new(host, port)
        break
      rescue ex : Socket::ConnectError
        K8sVault::Log.debug "count not connect to #{host}:#{port}: #{ex.message} (#{ex.class})"
      rescue ex
        K8sVault::Log.debug "count not connect to #{host}:#{port}: #{ex.message} (#{ex.class})"
      end
      sleep sleep_cycle
    end

    begin
      client << "hello\n"
    rescue ex : IO::Error
      K8sVault::Log.debug "#{ex.message} (IO::Error)"
      K8sVault::Log.error "failed to connect to K8s API, timeout reached"
      return false
    rescue ex
      K8sVault::Log.debug "#{ex.message} (ex.class)"
      K8sVault::Log.error "failed to connect to K8s API, timeout reached"
      return false
    end
    return true
  end

  # Output list of enabled contexts from K8SVAULT_CONFIG
  #
  # Returns Array(String) of enabled contexts
  # Raises `K8sVault::NoFileAccessError` if K8SVAULT_CONFIG is not accessible
  # Raises `K8sVault::ConfigParseError` if K8SVAULT_CONFIG cannot be parsed
  def self.list_enabled_contexts(file : String? = nil)
    file ||= K8sVault::K8SVAULT_CONFIG
    if File.readable?(file)
      begin
        config = K8sVault::ConfigReader.config(file)
      rescue YAML::ParseException
        raise K8sVault::ConfigParseError.new("unable to parse config \"#{file}\"")
      end
    else
      raise K8sVault::NoFileAccessError.new("\"#{file}\" is not readable")
    end
    config.contexts.map { |c| c.name if c.enabled == true }.compact
  end

  # Removed temporary KUBECONFIG, if present
  #
  # Return `nil`
  def self.cleanup : Nil
    K8sVault::Log.debug "cleaning up"
    File.delete(K8sVault::KUBECONFIG_TEMP) rescue nil
  end

  # Runs everything
  def self.run(options : Array(String))
    kubecontext = "_unset_"
    spawn_shell = false

    while options.size > 0
      case options.first
      when "-v", "--version"
        puts K8sVault::VERSION
        exit 0
      when "-h", "--help", "--usage"
        K8sVault.usage
        exit 0
      when "-d", "--debug"
        K8sVault::Log.debug = true
        options.shift
      when "example-config"
        K8sVault.example_config
        exit 0
      when "list-enabled-contexts"
        K8sVault.list_enabled_contexts.each { |c| puts c } rescue nil
        exit 0
      when "completion"
        K8sVault.completion
        exit 0
      when "exec"
        options.shift
        if options.empty?
          K8sVault::Log.error "missing context name, it must follow \"exec\", see --help"
          exit 1
        else
          kubecontext = options.first
          options.shift
        end
        if options.empty?
          K8sVault::Log.error "missing required argument \"--\" or \"-s\", see --help"
          exit 1
        else
          if options.first == "-s"
            spawn_shell = true
            options.shift
            break
          end
        end
      when "--"
        options.shift
        if options.empty?
          K8sVault::Log.error "command should follow \"--\", see --help"
          exit 1
        end
        break
      else
        K8sVault::Log.error "unexpected option \"#{options.first}\", see --help"
        exit 1
      end
    end

    # ensure SSH binary is available
    unless Process.find_executable("ssh")
      K8sVault::Log.error("could not find \"ssh\" binary in PATH")
      exit 1
    end

    # make sure kubecontext is set
    if kubecontext == "_unset_" || kubecontext.to_s.empty?
      K8sVault::Log.error "context name cannot be empty, it must follow \"exec\", see --help"
      exit 1
    end

    # no nested sessions
    if ENV.has_key?("K8SVAULT")
      K8sVault::Log.error "already running inside k8s-vault session, no nesting allowed"
      exit 1
    end

    # trap CTRL-C
    Signal::INT.trap do
      cleanup
      exit 0
    end

    # parse configs
    begin
      config = K8sVault.config(kubecontext: kubecontext)
      # write temp KUBECONFIG
      File.write(K8sVault::KUBECONFIG_TEMP, config.kubeconfig, perm = 0o0400)
    rescue K8sVault::UnconfiguredContextError
      K8sVault::Log.error "\"#{kubecontext}\" context is not found in #{K8sVault::K8SVAULT_CONFIG}"
      cleanup
      exit 1
    rescue K8sVault::ConfigParseError
      K8sVault::Log.error "unable to parse config file at #{K8sVault::K8SVAULT_CONFIG}"
      cleanup
      exit 1
    rescue ex
      K8sVault::Log.debug "#{ex.message} (#{ex.class})"
      K8sVault::Log.error "unexpected error"
      cleanup
      exit 1
    end

    # start SSH forwarding session
    begin
      forwarder = Process.new(
        "ssh",
        [
          "-N",
          "-L",
          "#{config.local_port}:#{config.remote_host}:#{config.remote_port}",
          config.ssh_jump_host,
        ],
        output: STDOUT,
        error: STDERR
      )

      unless K8sVault.wait_for_connection(port: config.local_port.to_i, timeout: config.k8s_api_timeout.to_i)
        forwarder.signal(Signal::TERM) rescue nil
        forwarder.wait rescue nil
        K8sVault.cleanup
        exit 1
      end
    rescue ex
      K8sVault::Log.debug "#{ex.message} (#{ex.class})"
      K8sVault::Log.error "failed to establish SSH session"
      K8sVault.cleanup
      exit 1
    end

    ENV["K8SVAULT"] = "1"
    ENV["KUBECONFIG"] = K8sVault::KUBECONFIG_TEMP
    K8sVault::Log.debug "using KUBECONFIG: #{K8sVault::KUBECONFIG_TEMP}"

    if spawn_shell
      K8sVault::Log.info "k8s-vault session started"
      # spawn a shell
      system(ENV["SHELL"])
      K8sVault::Log.warn "k8s-vault session terminated"
    else
      sleep 3
      cmd = options.first
      options.shift
      Process.run(cmd, options, {"KUBECONFIG" => K8sVault::KUBECONFIG_TEMP}, output: STDOUT, error: STDERR)
    end

    forwarder.signal(Signal::TERM)
    forwarder.wait
    K8sVault.cleanup
  end
end
