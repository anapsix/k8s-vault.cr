require "./k8s-vault"

include K8sVault::Helpers

cli_opts = ARGV

if cli_opts.empty?
  puts K8sVault.usage
  exit 0
end

kubecontext = "_unset_"
spawn_shell = false

while cli_opts.size > 0
  case cli_opts.first
  when "-v", "--version"
    puts K8sVault::VERSION
    exit 0
  when "-h", "--help", "--usage"
    puts K8sVault.usage
    exit 0
  when "-d", "--debug"
    K8sVault::Log.debug = true
    cli_opts.shift
  when "example-config"
    K8sVault.example_config
    exit 0
  when "completion"
    K8sVault::Log.info "not implemented yet"
    exit 0
  when "exec"
    cli_opts.shift
    kubecontext = cli_opts.first
    cli_opts.shift
    if cli_opts.size > 0 && cli_opts.first == "-s"
      spawn_shell = true
      cli_opts.shift
      break
    end
  when "--"
    cli_opts.shift
    break
  else
    K8sVault::Log.error "unexpected option #{cli_opts.first}"
    K8sVault.usage
    exit 1
  end
end

# ensure SSH binary is available
unless Process.find_executable("ssh")
  K8sVault::Log.error("could not find \"ssh\" binary in PATH")
  exit 1
end

# make sure kubecontext is set
if kubecontext == "_unset_"
  K8sVault::Log.error "missing context name, it must follow \"exec\""
  K8sVault.usage
  exit 1
end

# no nested sessions
if ENV.has_key?("K8SVAULT")
  K8sVault::Log.error "already running inside k8s-vault session, no nesting allowed"
  exit 1
end

def cleanup
  K8sVault::Log.debug "cleaning up"
  File.delete(K8sVault::KUBECONFIG_TEMP) rescue nil
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
      config.ssh_jump_host
    ],
    output: STDOUT,
    error: STDERR
  )

  unless wait_for_connection(port: config.local_port.to_i, timeout: config.k8s_api_timeout.to_i)
    forwarder.signal(Signal::TERM) rescue nil
    forwarder.wait rescue nil
    cleanup
    exit 1
  end
rescue ex
  K8sVault::Log.debug "#{ex.message} (#{ex.class})"
  K8sVault::Log.error "failed to establish SSH session"
  cleanup
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
  cmd = cli_opts.first
  cli_opts.shift
  Process.run(cmd, cli_opts, { "KUBECONFIG" => K8sVault::KUBECONFIG_TEMP }, output: STDOUT, error: STDERR)
end

forwarder.signal(Signal::TERM)
forwarder.wait
cleanup
