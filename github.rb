# Language: Ruby, Level: Level 3
require 'json'
require 'time'
require 'rest-client'
require 'logger'
require 'yaml'
require './ConfigLoader.rb'

class Github < ConfigLoader
    GITHUB_API = 'https://api.github.com'

    def initialize
        super()
    end


    def hasNextPage link
      if link.nil?
        return false
      else
        return link.include? 'next'
      end
    end

    def getNextPage link
      return parseLinkHeader(link)[:next]
    end

    def parseLinkHeader link
      links = Hash.new
      parts = link.split(',')
      parts.each do |part, index|
        section = part.split(';')
        url = section[0][/<(.*)>/,1]
        name = section[1][/rel="(.*)"/,1].to_sym
        links[name] = url
      end

      return links
    end
end
