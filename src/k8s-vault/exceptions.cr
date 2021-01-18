module K8sVault
  # Raised when requested context is missing from selected `KUBECONFIG`.
  class ConfigParseError < Exception
    def initialize(message = "unable to parse config", config : String? = nil)
      if config
        super("#{message} \"#{config}\"")
      else
        super(message)
      end
    end
  end

  # Raised when requested file is not readable.
  class NoFileAccessError < Exception
    def initialize(
      message = "file is not readable, doesn't exist or permissions issue",
      file : String? = nil
    )
      if file
        super("\"#{file}\" #{message}")
      else
        super(message)
      end
    end
  end

  # Raised when context is not configured in `K8SVAULT_CONFIG`
  class UnconfiguredContextError < Exception
    def initialize(
      message = "context is not configured in k8s-vault config",
      kubecontext : String? = nil
    )
      if kubecontext
        super("\"#{kubecontext}\" #{message}")
      else
        super(message)
      end
    end
  end

  # Raised when context is configured but is disabled in `K8SVAULT_CONFIG`
  class DisabledContextError < Exception
    def initialize(message = "context is disabled in k8s-vault config", kubecontext : String? = nil)
      if kubecontext
        super("\"#{kubecontext}\" #{message}")
      else
        super(message)
      end
    end
  end

  # Raises when unexpected option is encountered
  class UnexpectedOptionError < Exception
    def initialize(message = "unexpected option", option : String? = nil)
      if option
        super("\"#{option}\" #{message}")
      else
        super(message)
      end
    end
  end
end
