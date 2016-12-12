# Encoding: utf-8

module Utils

  class SimpleLogger

    class << self

      def warning(msg)
        $stderr.puts "Warning: #{msg}"
      end

      def error(msg)
        $stderr.puts "Error: #{msg}"
      end

      def info(msg)
        $stdout.puts msg.to_s
      end

    end

  end

end
