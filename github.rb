require 'json'
require 'time'
require 'rest-client'
require 'logger'
require 'yaml'

class Github 
    CONFIG = YAML.load_file('./config.yml')     
    GITHUB_API = 'https://api.github.com'     
    
    def initialize    
        @logger = Logger.new('logs.log', 'monthly')
        @logger.level = CONFIG['LOG_LEVEL'] || Logger::DEBUG
        RestClient.log = @logger
    end 
  
  
    def hasNextPage link
      if link.nil? 
        return false
      else 
        return link.include? 'next'
      end
    end    
end