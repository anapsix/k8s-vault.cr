require "./spec_helper"
require "../src/k8s-vault/helpers"

include K8sVault::Helpers

describe K8sVault::Helpers do
  config_file = "../k8s-vault_example.yaml"
  config_path = File.real_path("#{File.dirname(__FILE__)}/#{config_file}")

  config_file_bad = "./fixtures/k8s-vault_bad.yaml"
  config_path_bad = File.real_path("#{File.dirname(__FILE__)}/#{config_file_bad}")

  kubeconfig_file = "./fixtures/kubeconfig"
  kubeconfig_path = File.real_path("#{File.dirname(__FILE__)}/#{kubeconfig_file}")

  describe "#list_enabled_contexts" do
    it "lists enabled contexts" do
      list_enabled_contexts(config_path).should eq(["prod", "qa"])
    end

    it "raises K8sVault::ConfigParseError" do
      expect_raises(K8sVault::ConfigParseError, /^unable to parse config/) do
        list_enabled_contexts(config_path_bad)
      end
    end

    it "raises K8sVault::NoFileAccessError" do
      expect_raises(K8sVault::NoFileAccessError, /is not readable$/) do
        list_enabled_contexts("/tmp/k8s-vault_Uth1ui1b.yaml")
      end
    end
  end
end
