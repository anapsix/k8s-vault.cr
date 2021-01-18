module K8sVault
  class Log
    # Controls debug logging
    @@debug : Bool = false

    def self.debug
      @@debug
    end

    def self.debug=(value : Bool)
      @@debug = value
    end

    def self.debug(msg : String)
      return unless @@debug
      prefix = "DEBUG".colorize(:magenta)
      STDERR.puts("#{prefix}: #{msg}")
    end

    def self.info(msg : String)
      prefix = "INFO".colorize(:green)
      STDERR.puts("#{prefix}: #{msg}")
    end

    def self.warn(msg : String)
      prefix = "WARNING".colorize(:yellow)
      STDERR.puts("#{prefix}: #{msg}")
    end

    def self.error(msg : String)
      prefix = "ERROR".colorize(:red)
      STDERR.puts("#{prefix}: #{msg}")
    end
  end
end
