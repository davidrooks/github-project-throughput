# Language: Ruby, Level: Level 3
require 'json'
require 'time'
require 'rest-client'
require 'sinatra/base'
require 'tilt/erb'
require './project.rb'
require 'yaml'
require './github.rb'
require './configLoader.rb'
require 'date'

class App < Sinatra::Base
    $configLoader = ConfigLoader.new()
    PROJECT = Project.new()
    PROJECT.getProjectData()
    PROJECT.fetchPointsForInSprintIssues()
    $PROJECT_DATA = PROJECT.transformData()
    $PROJECT_BOARD = PROJECT.getBoard()
    $ISSUES_WITH_HIGHEST_POINTS = PROJECT.getIssuesWithPoints()
    # $PROJECT_DATA = {"2019-05-09"=>{"INFORMATION"=>1, "DONE"=>1}, "2019-05-22"=>{"ANALYSIS"=>2}, "2019-05-23"=>{"ANALYSIS"=>3}, "2019-05-30"=>{"ANALYSIS"=>2, "PRODUCT BACKLOG"=>1, "CODE REVIEW"=>1, "BLOCKED"=>3, "DONE"=>1}, "2019-05-24"=>{"ANALYSIS"=>2, "BLOCKED"=>1, "DONE"=>1}, "2019-06-03"=>{"ANALYSIS"=>2, "IN PROGRESS"=>2, "READY FOR QA"=>1, "IN QA"=>2}, "2019-05-31"=>{"ANALYSIS"=>1, "PRODUCT BACKLOG"=>3, "CODE REVIEW"=>2, "READY FOR QA"=>1, "DONE"=>4}, "2019-05-29"=>{"PRODUCT BACKLOG"=>3, "SPRINT BACKLOG"=>3, "CODE REVIEW"=>1, "READY FOR QA"=>2, "IN QA"=>1, "DONE"=>1}, "2019-05-28"=>{"IN PROGRESS"=>1, "READY FOR QA"=>1, "DONE"=>3}, "2019-05-20"=>{"IN PROGRESS"=>1, "DONE"=>2}, "2019-05-21"=>{"CODE REVIEW"=>1, "BLOCKED"=>2, "DONE"=>1}, "2019-05-08"=>{"BLOCKED"=>1}, "2019-05-14"=>{"BLOCKED"=>3}, "2019-05-16"=>{"DONE"=>3}, "2019-05-15"=>{"DONE"=>2}, "2019-05-13"=>{"DONE"=>1}}

    $ROUTE = '/'

    def active_page?(path='')
        request.path_info == '/' + path
    end

# Create /api/
# Use those api pages to run the .erb files, perhaps use jquery Fetch to load it?
# The api can then be ran once a night using cron job for data to be stored on a file etc. This file will contain daily data for creating graphs etc


    get '/' do
        redirect '/summary'
    end

    get '/api/points' do
        content_type :json
        $ROUTE = request.path_info

        $ISSUES_WITH_HIGHEST_POINTS.to_json
    end

    get '/api/sprint-points' do
        content_type :json
        $ROUTE = request.path_info

        totalSprintPoints.to_json
    end

    get '/api/summary' do
        content_type :json
        $ROUTE = request.path_info
        today = Date.today
        @cumulative_data = getCumulativeFlowData

        @title = $configLoader.getConfigValue('TITLE')
        @type = 'AreaChart'
        @stacked = true
        @open_tickets = getTotalInSprintIssues
        @closed_tickets = getTotalIssuesInAColumn("Done")
        data = getThroughputData
        throughput = data.last.last
        @throughput = data.last.last.round(2)
        work_days_required = throughput * @open_tickets
        days_required = (work_days_required + (work_days_required*2/7)).round
        projected_delivery_date = today + days_required
        @work_days_required = (work_days_required).round
        @projected_delivery_date = projected_delivery_date.iso8601

        @colors = $configLoader.getAllCumulativeFlowColors

        data = { cumulative_data: @cumulative_data, title: @title, type: @type, stacked: @stacked, open_tickets: @open_tickets, closed_tickets: @closed_tickets, throughput: @throughput, work_days_required: @work_days_required, projected_delivery_date: @projected_delivery_date, colors: @colors}.to_json

        data
    end

    get '/summary' do
        $ROUTE = request.path_info
        today = Date.today
        @cumulative_data = getCumulativeFlowData
        @totalSprintPoints = totalSprintPoints
        @title = $configLoader.getConfigValue('TITLE')
        @type = 'AreaChart'
        @stacked = true
        @open_tickets = getTotalInSprintIssues
        @closed_tickets = getTotalIssuesInAColumn("Done")
        data = getThroughputData
        throughput = data.last.last
        @throughput = data.last.last.round(2)
        work_days_required = throughput * @open_tickets
        days_required = (work_days_required + (work_days_required*2/7)).round
        projected_delivery_date = today + days_required
        @work_days_required = (work_days_required).round
        @projected_delivery_date = projected_delivery_date.iso8601

        @colors = $configLoader.getAllCumulativeFlowColors

        erb :index
    end

    get '/refresh' do
        PROJECT.getProjectData()
        $PROJECT_DATA = PROJECT.transformData()
        redirect '/summary'
    end

    get '/cumulative-flow-diagram' do
        $ROUTE = request.path_info
        @data  = getCumulativeFlowData
        @stacked = true
        @title = 'Cumulative Flow Diagram'
        @type = 'AreaChart'
        @colors = $configLoader.getAllCumulativeFlowColors
        erb :chart
    end

    get '/api/board' do
        content_type :json
        $ROUTE = request.path_info
        $PROJECT_BOARD.to_json
    end

    get '/api/config' do
        content_type :json
        $ROUTE = request.path_info
        config_file = File.open('./config.json')
        loadedConfig = JSON.load config_file
        loadedConfig.to_json
    end

    get '/api/cumulative-flow-diagram' do
        content_type :json
        $ROUTE = request.path_info
        @stacked = true
        @title = 'Cumulative Flow Diagram'
        @type = 'AreaChart'

        hashview = params['hashview']
        if (hashview == 'true')
            jsonData = getDataJson($configLoader.getAllColumns)
            previousResult = $configLoader.emptyBoardColumns

            $configLoader.getAllColumns.each_with_index do |column, j|
                jsonData.each_with_index do |d, i|
                    if d[column].class == Integer
                        d[column] = d[column] + previousResult[column]
                    end
                    previousResult = d
                end
            end
            @data = jsonData
        else
            @data  = getCumulativeFlowData
        end

        {title: @title, type: @type, stacked: @stacked, throughputData: @data}.to_json
    end

    get '/api/throughput' do
        content_type :json
        $ROUTE = request.path_info
        @stacked = false
        @title = 'Throughput'
        @type = 'ComboChart'

        hashview = params['hashview']

        if (hashview == 'true')
            @data = getDataJson($configLoader.getThroughputColumn)
        else
            @data  = getThroughputData
        end
        {title: @title, type: @type, stacked: @stacked, throughputData: @data}.to_json
    end

    get '/throughput' do
        $ROUTE = request.path_info
        @data  = getThroughputData
        @stacked = false
        @title = 'Throughput'
        @type = 'ComboChart'
        erb :chart
    end

    def totalSprintPoints()
        allColumns= $ISSUES_WITH_HIGHEST_POINTS
        sprintColumns = $configLoader.getInSprintColumns

        overallTotalIssues = 0

        sprintColumns.each_with_index do |sprintColumn, index|
            allColumns.each_with_index do | boardColumnWithPoints, i |

                if boardColumnWithPoints.include?(sprintColumn.upcase)
                    totalInColumn = 0
                    boardColumnWithPoints[1].each_with_index do |items, i|
                        totalInColumn = items.values.first + totalInColumn
                    end
                    overallTotalIssues = totalInColumn + overallTotalIssues
                end
            end
        end
        overallTotalIssues
    end

    def getThroughputData()
        dataJson = getDataJson($configLoader.getThroughputColumn)
        current = []
        total_done = 0

        dataJson.each_with_index do |d,i|
            total_done = d["DONE"] + total_done

            d["average"] = total_done.to_f/(i+1)
            response = []
            response[0] = d[:DATE]
            response[1] = d["DONE"]
            response[2] = total_done.to_f/(i+1)
            current << response
        end
        header = ['date', 'done', 'average']
        [header].concat(current)
    end


    def getCumulativeFlowData()
        data = getData(['TIME'].concat($configLoader.getUseForCumulativeFlowChartColumns))
        data.each_with_index do |d, i|
            if i <= 1
                next
            end
            x = 1
            while x < d.length
                data[i][x] += data[i-1][x]
                x += 1
            end
        end

        data
    end

    def getTotalInSprintIssues()
        sprintColumns = $configLoader.getInSprintColumns
        board = $PROJECT_BOARD
        overallTotalIssues = 0

        sprintColumns.each_with_index do |sprintColumn, index|
            board.each_with_index do | boardColumn, i |
                if boardColumn.include?(sprintColumn.upcase)
                    totalInColumn = board[sprintColumn.upcase].length
                    overallTotalIssues = totalInColumn + overallTotalIssues
                    break
                end
            end
        end
        overallTotalIssues
    end

    def getTotalIssuesInAColumn(columnName)
        board = $PROJECT_BOARD
        overallTotalIssues = 0

        board.each_with_index do | boardColumn, i |
            if boardColumn.include?(columnName.upcase)
                totalInColumn = board[columnName.upcase].length
                overallTotalIssues = totalInColumn + overallTotalIssues
            end
        end

        overallTotalIssues
    end

    def getDataJson(format)
        response = []
        min_date = Date.parse($PROJECT_DATA.keys.sort.first)
        max_date = Date.today

        min_date.upto(max_date) do |d|
            if d.saturday? || d.sunday?
                next
            end
            current = {}
            format.each_with_index do |key, index|
                current = {"DATE": d.iso8601}
                if $PROJECT_DATA.has_key? d.iso8601
                    format.each_with_index do |k, i|
                        current[format[i].upcase] = $PROJECT_DATA[d.iso8601][format[i].upcase] || 0
                    end
                else
                    format.each_with_index do |k, i|
                        current[format[i].upcase] = 0
                    end
                end
            end
            response << current
        end
        response
    end

    def getData(format)
        response = []
        response << format

        min_date = Date.parse($PROJECT_DATA.keys.sort.first)
        max_date = Date.today

        previous = []
        min_date.upto(max_date) do |d|
            if d.saturday? || d.sunday?
                next
            end
            current = []
            format.each_with_index do |key, index|
                if key == 'TIME'
                    current[0] = d.iso8601
                else
                    if $PROJECT_DATA.has_key? d.iso8601
                        current[index] = $PROJECT_DATA[d.iso8601][key.upcase] || 0
                    else
                        current[index] = 0
                    end
                end
            end
            response << current
        end
        response
    end
end
