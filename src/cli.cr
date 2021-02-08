require "./k8s-vault"

if ARGV.empty?
  STDERR.puts "k8s-vault version #{K8sVault::VERSION}"
  STDERR.puts "see --help for usage details"
  exit 1
end

K8sVault.run(ARGV)
