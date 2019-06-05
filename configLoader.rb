# Language: Ruby, Level: Level 3
require 'json'
require 'time'
require 'rest-client'
require 'logger'

class ConfigLoader

    def initialize
        config_file = File.open('./config.json')
        @loadedConfig = JSON.load config_file

        # @logger = Logger.new('logs.log', 'monthly')
        @logger = Logger.new(STDOUT)
        @logger.level = @loadedConfig['LOG_LEVEL'] || Logger::DEBUG

        RestClient.log = @logger
    end

    def getConfigValue key
        if key.nil?
            return ""
        else
            return @loadedConfig[key]
        end
    end
end
