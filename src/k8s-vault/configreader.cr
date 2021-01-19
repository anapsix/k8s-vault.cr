require "semantic_version"
require "yaml"
require "./constants"
require "./exceptions"
require "./log"

module K8sVault
  include K8sVault::Constants

  # Implements YAML parser for `k8s-vault.yaml`
  #
  # Usage example:
  #
  # ```
  # require "k8s-vault/configreader"
  #
  # # if path is omitted, K8SVAULT_CONFIG env variable will be used
  # # if env variable is unset, it defaults to "~/.kube/k8s-vault.yaml"
  # reader = KCE::ConfigReader.new
  # config = reader.config
  # pp! config
  #
  # # reading from alternative path
  # reader = K8sVault::ConfigReader.new("/path/to/k8s-vault.yaml")
  #
  # # getting config via class method
  # K8sVault::ConfigReader.config
  # # with custom path to `k8s-vault.yaml`
  # K8sVault::ConfigReader.config("/path/to/k8s-vault.yaml")
  # ```
  struct ConfigReader
    struct K8sVaultConfig
      include YAML::Serializable
      include YAML::Serializable::Unmapped

      # Used for parsing `.ssh_forwarding_port` in `K8SVAULT_CONFIG`
      struct SSHForwardingPort
        include YAML::Serializable

        # From `K8SVAULT_CONFIG`: `.ssh_forwarding_port.random`
        getter random : Bool

        # From `K8SVAULT_CONFIG`: `.ssh_forwarding_port.static`
        getter static : Int32
      end

      # Used for parsing `.clusters` in `K8SVAULT_CONFIG`
      struct Context
        include YAML::Serializable

        # From `K8SVAULT_CONFIG`: `.clusters[*].name`
        getter name : String

        # From `K8SVAULT_CONFIG`: `.clusters[*].enabled`
        getter enabled : Bool = true

        # From `K8SVAULT_CONFIG`: `.clusters[*].ssh_jump_host`
        getter ssh_jump_host : String
      end

      # From `K8SVAULT_CONFIG`: `.version`, in seconds
      getter version : String?

      # From `K8SVAULT_CONFIG`: `.k8s_api_timeout`, in seconds
      getter k8s_api_timeout : Int32

      # From `K8SVAULT_CONFIG`: `.ssh_forwarding_port`
      getter ssh_forwarding_port : SSHForwardingPort

      # From `K8SVAULT_CONFIG`: `.contexts`
      getter contexts : Array(Context)
    end

    # Path to `K8SVAULT_CONFIG`
    getter file : String

    # Parsed `K8SVAULT_CONFIG` object
    getter config : K8sVaultConfig

    # Creates an instance of `K8sVault:ConfigReader`
    #
    # When `file` is not passed, uses value of `K8SVAULT_CONFIG`.
    # If `K8SVAULT_CONFIG` is unset, defaults to `~/.kube/k8s-vault.yaml`
    #
    # Raises `Exception` if file is not readable
    def initialize(file : String? = nil)
      file ||= K8sVault::K8SVAULT_CONFIG
      @file = file
      if File.readable?(file)
        begin
          config = K8sVaultConfig.from_yaml(File.read(@file))
        rescue YAML::ParseException
          raise K8sVault::ConfigParseError.new("unable to parse config \"#{@file}\"")
        end
        @config = config
        unless @config.@yaml_unmapped.empty?
          K8sVault::Log.warn "unmapped values detected in config \"#{@file}\""
          K8sVault::Log.debug "unmapped values: #{@config.@yaml_unmapped}"
        end
      else
        raise K8sVault::NoFileAccessError.new("\"#{file}\" is not readable")
      end
    end

    # Returns YAML parsed config object.
    #
    # When `file` is not passed, uses value of `K8SVAULT_CONFIG`.
    # If `K8SVAULT_CONFIG` is unset, defaults to `~/.kube/k8s-vault.yaml`
    #
    # Raises `Exception` if file is not readable
    def self.config(file : String? = nil)
      self.new(file).config
    end
  end
end
