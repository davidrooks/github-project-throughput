# Language: Ruby, Level: Level 3
require 'json'
require 'time'
require 'rest-client'
require 'sinatra/base'
require 'tilt/erb'
require './dummyData.rb'
require './project.rb'
require 'yaml'
require './github.rb'
require './configLoader.rb'
require './apiRoutes.rb'
require './modelAccessor.rb'
require './dataUtils.rb'
require 'date'
require './githubProcessor.rb'

class App < Sinatra::Base
    $configLoader = ConfigLoader.new()
    $dataUtils = DataUtils.new
    $githubProcessor = GithubProcessor.new
    $modelAccessor = ModelAccessor.new()

    if $configLoader.getConfigValue('useDummyData')
        puts ">>>>> using dummy Data"
        PROJECT = DummyData.new()
        PROJECT.getBoardData()
        PROJECT.fetchPointsForInSprintIssues()
        PROJECT.transformDataWithSinglePoint()
        PROJECT.transformDataWithPoints()
    else
        PROJECT = Project.new()
        PROJECT.getBoardData()
        PROJECT.fetchPointsForInSprintIssues()
        PROJECT.transformDataWithSinglePoint()
        PROJECT.transformDataWithPoints()
    end

    $ROUTE = '/'

    def active_page?(path='')
        request.path_info == '/' + path
    end

    get '/' do
        redirect '/summary'
    end

    get '/summary' do
        $ROUTE = request.path_info
        today = Date.today
        @cumulative_data = $dataUtils.getCumulativeFlowData
        @title = $configLoader.getConfigValue('TITLE')
        @type = 'AreaChart'
        @stacked = true
        data = $dataUtils.getThroughputData
        pointsData = $dataUtils.getPointsThroughputData
        throughput = data.last.last
        pointsThroughput = pointsData.last.last
        @open_tickets = $dataUtils.getTotalInSprintIssues
        work_days_required = pointsThroughput * @open_tickets
        days_required = (work_days_required + (work_days_required*2/7)).round
        projected_delivery_date = today + days_required

        @colors = $configLoader.getAllCumulativeFlowColors.reverse
        @currentSprintColumns = $configLoader.getInSprintColumns.join("<br/> ").capitalize
        @throughputColumns = $configLoader.getThroughputColumn.join("<br/> ").capitalize

        @projected_delivery_date = projected_delivery_date.iso8601
        @work_days_required = (work_days_required).round
        @closed_tickets = $dataUtils.getTotalIssuesInAColumn("Done")

        @ticketsThroughput = throughput.round(2)
        @pointsThroughput = pointsThroughput.round(2)
        @totalSprintPoints = $dataUtils.totalSprintPoints

        erb :index
    end

    get '/refresh' do
        PROJECT.getBoardData()
        PROJECT.transformDataWithSinglePoint()
        redirect '/summary'
    end

    get '/cumulative-flow-diagram' do
        $ROUTE = request.path_info
        @data  = $dataUtils.getCumulativeFlowData
        @stacked = true
        @title = 'Cumulative Flow Diagram'
        @type = 'AreaChart'
        @colors = $configLoader.getAllCumulativeFlowColors.reverse
        erb :chart
    end

    get '/throughput' do
        $ROUTE = request.path_info
        @data  = $dataUtils.getThroughputData
        @stacked = false
        @title = 'Throughput'
        @type = 'ComboChart'
        erb :chart
    end

    use ApiRoutes
end
