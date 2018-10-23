require './github.rb'

class Project < Github
    PROJECTS_PATH = '/projects/' + CONFIG['PROJECT'] + '/columns'       
    
    def initialize    
        super()
    end     
  
    def getData
      board = Hash.new()
      kanban = Hash.new()
  
      @logger.debug 'getting issues from ' + GITHUB_API
      issues = []
      begin
        result = RestClient.get GITHUB_API + PROJECTS_PATH, :accept => 'application/vnd.github.inertia-preview+json', :'Authorization' => 'token ' + CONFIG['OAUTH']
        columns = JSON.parse(result)        
        columns.each do |col|   
            cards = []                      
            result = RestClient.get col['cards_url'], :accept => 'application/vnd.github.inertia-preview+json', :'Authorization' => 'token ' + CONFIG['OAUTH']
            cards += JSON.parse(result)
            while hasNextPage(result.headers[:link])                
                result = result = RestClient.get result.headers[:link].split(';')[0][1...-1], :accept => 'application/vnd.github.inertia-preview+json', :'Authorization' => 'token ' + CONFIG['OAUTH']
                cards += JSON.parse(result)
            end       
            board[col['name']] = cards     
        end        
                 
      rescue Exception => e
        @logger.debug '-----------------------'
        @logger.debug  'exception!'
        @logger.debug e.to_s
        @logger.debug e.backtrace
        @logger.debug '-----------------------'
      end
       
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
    
      @logger.info '=============================================='
      @logger.info 'Current ticket state...'
      @logger.info kanban.to_s
      @logger.info '=============================================='        
      return kanban
    end
end