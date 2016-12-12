# Encoding: utf-8

require 'yaml'
require 'utils/simple_logger'

module Utils

  class HandlerUtils

    def self.get_configuration(handler_name)
      var_name      = environment_variable_name(handler_name)
      user_provided = ENV[var_name]
      if user_provided
        begin
          user_provided_value = YAML.load(user_provided)
          return user_provided_value if user_provided_value.is_a?(Hash)
          SimpleLogger.error("Configuration value in environment variable #{var_name} is not valid: #{user_provided_value}")
        rescue Psych::SyntaxError => ex
          SimpleLogger.error("Configuration value in environment variable #{var_name} has invalid syntax: #{ex}")
        end
      end
      {}
    end

    ENVIRONMENT_VARIABLE_PATTERN = 'BLUEMIX_APP_MGMT_'.freeze

    def self.environment_variable_name(handler_name)
      ENVIRONMENT_VARIABLE_PATTERN + handler_name.upcase
    end

    private_constant :ENVIRONMENT_VARIABLE_PATTERN

    private_class_method :environment_variable_name

  end

end
