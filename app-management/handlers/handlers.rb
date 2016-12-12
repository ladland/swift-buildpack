# Encoding: utf-8

require 'json'
require 'set'
require 'utils/handler'
require 'utils/simple_logger'

module Utils

  class Handlers

    def initialize(handlers_dir, type = 'start')
      @handlers = {}

      Dir.glob("#{handlers_dir}/#{type}-*/info.json").each do |file|
        begin
          info = JSON.load(File.new(file))
        rescue JSON::ParserError => e
          SimpleLogger.error("Error loading #{file}: #{e.message}")
        end

        name = file[%r{#{type}-(.+)/}, 1]

        handler = Handler.new(handlers_dir, name, info, type)

        # skip non-public handlers
        next unless handler.public?

        @handlers[name] = handler
      end
    end

    def get_handler(name)
      @handlers[name]
    end

    def validate(enabled_handlers)
      valid = Set.new
      invalid = Set.new
      enabled_handlers.each do |enabled_handler|
        handler = get_handler(enabled_handler)
        if handler.nil?
          invalid << enabled_handler
        else
          valid << enabled_handler
        end
      end
      [valid.to_a, invalid.to_a]
    end

    def proxy_required?(enabled_handlers)
      proxy_required = false
      enabled_handlers.each do |enabled_handler|
        handler = get_handler(enabled_handler)
        next if handler.nil?
        return false if enabled_handler.eql?('noproxy')
        proxy_required = true if handler.proxy_required?
      end
      proxy_required
    end

    def executions(enabled_handlers)
      sync = []
      async = []
      enabled_handlers.each do |enabled_handler|
        handler = get_handler(enabled_handler)
        next if handler.nil?
        if handler.background?
          async << handler
        else
          sync << handler
        end
      end
      [sync, async]
    end

  end

end
