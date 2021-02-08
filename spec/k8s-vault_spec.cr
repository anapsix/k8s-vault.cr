require "./spec_helper"

describe K8sVault do
  version_file = "../VERSION"
  version_path = File.real_path("#{File.dirname(__FILE__)}/#{version_file}")
  version = File.read(version_path).chomp

  config_file = "../k8s-vault_example.yaml"
  config_path = File.real_path("#{File.dirname(__FILE__)}/#{config_file}")

  config_file_bad = "./fixtures/k8s-vault_bad.yaml"
  config_path_bad = File.real_path("#{File.dirname(__FILE__)}/#{config_file_bad}")

  kubeconfig_file = "./fixtures/kubeconfig"
  kubeconfig_path = File.real_path("#{File.dirname(__FILE__)}/#{kubeconfig_file}")

  it "returns expected version" do
    K8sVault::VERSION.should eq(version)
  end

  it "returns expected K8SVAULT_CONFIG" do
    K8sVault::K8SVAULT_CONFIG.should eq(ENV.fetch("K8SVAULT_CONFIG", "#{ENV["HOME"]}/.kube/k8s-vault.yaml"))
  end

  it "returns expected KUBECONFIG" do
    K8sVault::KUBECONFIG.should eq(ENV.fetch("KUBECONFIG", "#{ENV["HOME"]}/.kube/config"))
  end

  it "reads configs" do
    config = K8sVault.config(
      kubecontext: "prod",
      config_path: config_path,
      kubeconfig_path: kubeconfig_path
    )

    config.kubecontext.should eq("prod")
    config.config_path.should eq(config_path)
    config.kubeconfig_path.should eq(kubeconfig_path)
    config.ssh_jump_host.should eq("jumphost.prod.example.com")
    config.remote_host.should eq("10.10.10.10")
    config.remote_port.should eq("6443")
    config.local_port.to_i.should be_close(35_000, 5_000)
    config.k8s_api_timeout.should eq("5")
  end

  it "raises K8sVault::UnconfiguredContextError" do
    expect_raises(K8sVault::UnconfiguredContextError, "\"not-there\" context is not configured in k8s-vault config") do
      K8sVault.config(
        kubecontext: "not-there",
        config_path: config_path,
        kubeconfig_path: kubeconfig_path
      )
    end
  end

  it "raises K8sVault::DisabledContextError" do
    expect_raises(K8sVault::DisabledContextError, "\"dev\" context is disabled in k8s-vault config") do
      K8sVault.config(
        kubecontext: "dev",
        config_path: config_path,
        kubeconfig_path: kubeconfig_path
      )
    end
  end

  it "raises K8sVault::ConfigParseError" do
    expect_raises(K8sVault::ConfigParseError, /^unable to parse config/) do
      K8sVault.config(
        kubecontext: "prod",
        config_path: config_path_bad,
        kubeconfig_path: kubeconfig_path
      )
    end
  end
end
