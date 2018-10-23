require './github.rb'

class Issues 
    CONFIG = YAML.load_file('./config.yml')    
    ISSUES_PATH = '/search/issues'
    QUERY = {'q' => 'repo:' + CONFIG['REPO'], 'per_page' => 100, 'sort' => 'created', 'direction' => 'desc', 'project' => CONFIG['PROJECT']}
    
    def initialize    
       super()
    end 
    
    def getData
      kanban = Hash.new()
  
      @logger.debug 'getting issues from ' + GITHUB_API
      issues = []
      begin
        result = RestClient.get GITHUB_API + ISSUES_PATH, :params => QUERY, :accept => :json, :'Authorization' => 'token ' + CONFIG['OAUTH']
        issues += JSON.parse(result)['items']
  
        while hasNextPage(result.headers[:link])
          result = result = RestClient.get result.headers[:link].split(';')[0][1...-1], :accept => :json, :'Authorization' => 'token ' + CONFIG['OAUTH']
          issues += JSON.parse(result)['items']
        end
      rescue Exception => e
        @logger.debug '-----------------------'
        @logger.debug  'exception!'
        @logger.debug e.to_s
        @logger.debug e.backtrace
        @logger.debug '-----------------------'
      end
  
      
  
      @logger.debug 'got ' + issues.count.to_s + ' issues'
      details = []
      throughput = 0
  
      issues.each do |issue|
        opened_on = Date.parse(issue['created_at'].to_s).iso8601
        if !kanban.has_key? opened_on
          kanban[opened_on] = {'OPEN': 1, 'DONE': 0}
        else      
          kanban[opened_on][:OPEN] += 1
        end
        
        if !issue['closed_at'].nil? 
          closed_on = Date.parse(issue['closed_at']).iso8601
          if !kanban.has_key? closed_on
            kanban[closed_on] = {'OPEN': 0, 'DONE': 1}
          else
            kanban[closed_on][:DONE] += 1
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