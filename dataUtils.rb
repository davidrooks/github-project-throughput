require './githubProcessor.rb'
require './ModelAccessor.rb'

class DataUtils

    $githubProcessor = GithubProcessor.new
    $modelAccessor = ModelAccessor.new

    def totalSprintPoints()
        allColumns= $modelAccessor.getProjectModel.getTransformedIssuesWithSinglePoint
        sprintColumns = $configLoader.getInSprintColumns
        overallTotalIssues = 0

        sprintColumns.each_with_index do |sprintColumn, index|
            allColumns.each do | date, boardColumnWithPoints |
                if boardColumnWithPoints.include?(sprintColumn.upcase)
                    totalInColumn = boardColumnWithPoints[sprintColumn.upcase].to_i
                    overallTotalIssues = totalInColumn + overallTotalIssues
                end
            end
        end
        overallTotalIssues
    end

    def getThroughputData()
        dataJson = $githubProcessor.getDataJson($configLoader.getThroughputColumn)
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

    def getPointsThroughputData()
        dataJson = $githubProcessor.getDataJsonWithPoints($configLoader.getThroughputColumn)
        allColumns= $modelAccessor.getProjectModel.getIssueWithPoints
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
        data = $githubProcessor.getData(['TIME'].concat($configLoader.getUseForCumulativeFlowChartColumns.reverse))
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
        board = $modelAccessor.getProjectModel.getBoard
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
        board = $modelAccessor.getProjectModel.board
        overallTotalIssues = 0

        board.each_with_index do | boardColumn, i |
            if boardColumn.include?(columnName.upcase)
                totalInColumn = board[columnName.upcase].length
                overallTotalIssues = totalInColumn + overallTotalIssues
            end
        end

        overallTotalIssues
    end

end
