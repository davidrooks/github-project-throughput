# Language: Ruby, Level: Level 3
require './github.rb'
require './ConfigLoader.rb'

class Project < Github

    def initialize
        super()
    end
    $configLoader = ConfigLoader.new()
    PROJECT_PATH = '/projects/' + $configLoader.getConfigValue('PROJECT') + '/columns'
    PROJECTS_PATH = '/repos/' + $configLoader.getConfigValue('REPO') + '/projects'

    $BOARD = Hash.new()


    #   can be used to find the ID of your github projects as this is not exposed by github website
    def getProjectID()
        result = RestClient.get GITHUB_API + PROJECTS_PATH, :accept => 'application/vnd.github.inertia-preview+json', :'Authorization' => 'token ' + $configLoader.getConfigValue('OAUTH')
        result = JSON.parse(result)
    end

    def getProjectData()
        board = Hash.new()
        @logger.debug 'getting issues from ' + GITHUB_API
        begin
            result = RestClient.get GITHUB_API + PROJECT_PATH, :accept => 'application/vnd.github.inertia-preview+json', :'Authorization' => 'token ' + $configLoader.getConfigValue('OAUTH')
            columns = JSON.parse(result)

            columns.each do |col|
                cards = []

                result = RestClient.get col['cards_url'], :accept => 'application/vnd.github.inertia-preview+json', :'Authorization' => 'token ' + $configLoader.getConfigValue('OAUTH')
                cards += JSON.parse(result)
                while hasNextPage(result.headers[:link])
                    result = RestClient.get getNextPage(result.headers[:link]), :accept => 'application/vnd.github.inertia-preview+json', :'Authorization' => 'token ' + $configLoader.getConfigValue('OAUTH')
                    cards += JSON.parse(result)
                end
                board[col['name'].upcase] = cards
                @logger.info "#{cards.length} cards in #{col['name']} column"
            end

        rescue Exception => e
            @logger.debug '-----------------------'
            @logger.debug  'exception!'
            @logger.debug e.to_s
            @logger.debug e.backtrace
            @logger.debug '-----------------------'
        end
        $BOARD = board
    end

    def fetchLabelsForAllIssues
        kanban = Hash.new()

        board = $BOARD
        issue_labels = []
        board.each do |column, cards|
            # puts "cards #{cards}"
            puts "column #{column}"
            cards.each do |card|
                if card.include?('content_url')
                    issue_url = card['content_url']
                    puts "issue_url #{issue_url}"
                    result = RestClient.get issue_url, :accept => 'application/vnd.github.inertia-preview+json', :'Authorization' => 'token ' + $configLoader.getConfigValue('OAUTH')
                    issue = JSON.parse(result)
                    puts "issue result #{issue}"
                    if issue.include?('labels')
                        issue_labels = issue.labels
                        puts "?>>>>>>> issue_labels #{issue_labels}"
                    end
                end
            end
        end
        issue_labels
    end


    def storePoints()
        # store the state of the board start of the day and end of the day
    end

    def explanationField()
    # This is to identify why the number of cards / points has increased in the Todo columns in the middle of the sprint
    end

    def sprintReport()
        #
    end

    def getBoard()
        return $BOARD
    end

    def estimatedSizeInColumns()
        # Aim is to take the label "Estimate 2" and add them
        # Also to fetch other type of cards and add them
        # Also to fetch bug card and give them a pointer
        # Also to fetch investigation cards and give them a pointer
        # kanban = Hash.new()

        # board = $BOARD
        #
        # board.each do |column, cards|
        #     cards.each do |card|
        #
        #     end
        # end
    end

    def transformData()
      kanban = Hash.new()

      board = $BOARD

      board.each do |column, cards|
        cards.each do |card|
            opened_on = Date.parse(card['created_at'].to_s).iso8601
            updated_on = Date.parse(card['updated_at'].to_s).iso8601

            if column.upcase.eql? 'TO DO'
                if !kanban.has_key? opened_on
                    kanban[opened_on] = Hash.new()
                end

                if !kanban[opened_on].has_key? 'TO DO'
                    kanban[opened_on]['TO DO'] = 1
                else
                    kanban[opened_on]['TO DO'] += 1
                end
            else
                if !kanban.has_key? updated_on
                    kanban[updated_on] = Hash.new()
                end
                if !kanban[updated_on].has_key? column.upcase
                    kanban[updated_on][column.upcase] = 1
                else
                    kanban[updated_on][column.upcase] += 1
                end
            end
        end
      end
      puts 'transformed data'
      @logger.info '=============================================='
      @logger.info 'Current ticket state...'
      @logger.info kanban.to_s
      @logger.info '=============================================='
      return kanban
    end
end
