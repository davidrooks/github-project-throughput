class ApiRoutes < Sinatra::Base

    get '/api/points' do
        content_type :json
        $ROUTE = request.path_info

        $modelAccessor.getProjectModel.getIssueWithPoints.to_json
    end

    get '/api/transformed-points' do
        content_type :json
        $ROUTE = request.path_info

        $modelAccessor.getProjectModel.getTransformedIssuesWithSinglePoint.to_json
    end

    get '/api/sprint-points' do
        content_type :json
        $ROUTE = request.path_info

        $dataUtils.totalSprintPoints.to_json
    end

    get '/api/summary' do
        content_type :json
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

        data = { cumulative_data: @cumulative_data, currentSprintColumns: @currentSprintColumns, title: @title, type: @type, stacked: @stacked, open_tickets: @open_tickets, closed_tickets: @closed_tickets, throughput: @throughput, work_days_required: @work_days_required, projected_delivery_date: @projected_delivery_date, colors: @colors}.to_json

        data
    end

    get '/api/board' do
        content_type :json
        $ROUTE = request.path_info
        $modelAccessor.getProjectModel.board.to_json
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
        @colors = $configLoader.getAllCumulativeFlowColors.reverse

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
            @data  = $dataUtils.getCumulativeFlowData
        end

        {title: @title, type: @type, stacked: @stacked, throughputData: @data, colors: @colors}.to_json
    end

    get '/api/ticket-throughput' do
        content_type :json
        $ROUTE = request.path_info
        @stacked = false
        @title = 'Ticket throughput'
        @type = 'ComboChart'

        hashview = params['hashview']

        if (hashview == 'true')
            @data = $githubProcessor.getDataJson($configLoader.getThroughputColumn)
        else
            @data  = $dataUtils.getThroughputData
        end
        {title: @title, type: @type, stacked: @stacked, throughputData: @data}.to_json
    end

    get '/api/points-throughput' do
        content_type :json
        $ROUTE = request.path_info
        @stacked = false
        @title = 'Points throughput'
        @type = 'ComboChart'
        @data  = $dataUtils.getPointsThroughputData
        {title: @title, type: @type, stacked: @stacked, throughputData: @data}.to_json
    end
end
