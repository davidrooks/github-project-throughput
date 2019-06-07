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

    def getAllColumns
        allColumns = getConfigValue('COLUMNS')
        result = []
        allColumns.each_with_index do |column, i|
            result << column['name'].upcase
        end
        result
    end

    def getAllCumulativeFlowColors
        allColumns = getConfigValue('COLUMNS')
        result = []
        allColumns.each_with_index do |column, i|
            if column['useForCumulativeFlowChart'] == true
                result << column['color']
            end
        end
        result
    end

    def getInSprintColumns
        allColumns = getConfigValue('COLUMNS')
        result = []

        allColumns.each_with_index do |column, i|
            if column['inSprint'] == true
                result << column['name'].upcase
            end
        end
        result
    end

    def getUseForCumulativeFlowChartColumns
        allColumns = getConfigValue('COLUMNS')
        result = []

        allColumns.each_with_index do |column, i|
            if column['useForCumulativeFlowChart'] == true
                result << column['name'].upcase
            end
        end
        result
    end

    def getThroughputColumn
        allColumns = getConfigValue('COLUMNS')
        result = []

        allColumns.each_with_index do |column, i|
            if column['throughputMap'] == true
                result << column['name'].upcase
            end
        end
        result
    end

    def emptyBoardColumns
        allColumns = getConfigValue('COLUMNS')
        result = {}
        allColumns.each_with_index do |column, i|
            result[column['name'].upcase] = 0
        end
        result[:DATE] = "01/01/2019"

        result
    end
end
