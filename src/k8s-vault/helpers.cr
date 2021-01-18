require "socket"
require "./log"

module K8sVault
  module Helpers
    # Waits for connection to TCP port of the server for the duration of timeout
    #
    # Returns `true` if connection is successful, otherwise `false`
    #
    # Example:
    # ```
    # unless wait_for_connection(host: "localhost", port: 8080, timeout: 10, sleep_cycle: 1)
    #  STDERR.puts "failed to establish connection within 10 seconds"
    #  exit 1
    # end
    # ```
    def wait_for_connection(host : String = "localhost", port : Int32 = 80, timeout : Int32 = 5, sleep_cycle : Float32 = 0.25) : Bool
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
  end
end
