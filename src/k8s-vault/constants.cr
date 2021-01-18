module K8sVault
  module Constants
    # :nodoc:
    VERSION = {{ read_file("#{__DIR__}/../../VERSION").strip }}
    PID = Process.pid
    K8SVAULT_CONFIG = ENV.fetch("K8SVAULT_CONFIG", "#{ENV["HOME"]}/.kube/k8s-vault.yaml")
    KUBECONFIG = ENV.fetch("KUBECONFIG", "#{ENV["HOME"]}/.kube/config")
    KUBECONFIG_TEMP = File.join(File.dirname(KUBECONFIG), "k8s-vault-kubeconfig-#{PID}.yaml")
    RANDOM_PORT_OFFSET = 30_000
    RANDOM_PORT_RANGE = 10_000
  end
end
