# Encoding: utf-8

module Utils

  class Handler

    PUBLIC = 'public'.freeze
    PROXY_REQUIRED = 'proxy_required'.freeze
    BACKGROUND = 'background'.freeze

    attr_reader :start_script

    def initialize(base_dir, name, info, type = 'start')
      @info = info
      @start_script = "#{base_dir}/#{type}-#{name}/run"
    end

    def proxy_required?
      # default is true
      @info[PROXY_REQUIRED].nil? || @info[PROXY_REQUIRED]
    end

    def background?
      # default is false
      if @info[BACKGROUND].nil?
        false
      elsif @info[BACKGROUND]
        true
      else
        false
      end
    end

    def public?
      # default is true
      @info[PUBLIC].nil? || @info[PUBLIC]
    end

  end

end
