require 'json'
require 'time'
require 'rest-client'
require 'sinatra/base'
require 'tilt/erb'
require './project.rb'
require 'yaml'
require 'date'

class App < Sinatra::Base    
  CONFIG = YAML.load_file('./config.yml')  
  PROJECT = Project.new()
  PROJECT.getProjectData()
  $PROJECT_DATA = PROJECT.transformData()
  # $PROJECT_DATA = {"2018-10-15"=>{"TO DO"=>8, "DONE"=>3}, "2018-10-29"=>{"TO DO"=>3, "BLOCKED"=>3, "READY FOR DEV"=>1, "IN DEVELOPMENT"=>1, "IN TEST"=>1, "FUNCTIONAL TEST AUTOMATION"=>1}, "2018-10-19"=>{"TO DO"=>1, "READY FOR DESIGN"=>1, "READY FOR DEV"=>8}, "2018-10-17"=>{"TO DO"=>1, "READY FOR DEV"=>8, "IN DEVELOPMENT"=>2, "DONE"=>1}, "2018-10-23"=>{"BLOCKED"=>8}, "2018-10-24"=>{"BLOCKED"=>1, "DONE"=>1}, "2018-10-18"=>{"READY FOR DESIGN"=>2, "READY FOR DEV"=>1}, "2018-10-31"=>{"IN DESIGN"=>1, "READY FOR DEV"=>3, "IN DEVELOPMENT"=>1, "IN REVIEW"=>2, "DONE"=>1}, "2018-10-30"=>{"READY FOR DEV"=>3, "IN DEVELOPMENT"=>1, "IN REVIEW"=>1, "DONE"=>4}, "2018-11-01"=>{"READY FOR DEV"=>1, "FUNCTIONAL TEST AUTOMATION"=>1, "DONE"=>1}, "2018-10-26"=>{"READY FOR DEV"=>11, "IN TEST"=>1, "DONE"=>4}, "2018-10-22"=>{"READY FOR DEV"=>2, "IN DEVELOPMENT"=>3}, "2018-10-16"=>{"IN DEVELOPMENT"=>1, "DONE"=>1}}  
  $ROUTE = '/'

  def active_page?(path='')
    request.path_info == '/' + path
  end

  get '/' do    
    redirect '/summary'
  end

  get '/summary' do
    $ROUTE = request.path_info 
    xmas_holidays = 10
    today = Date.today
    target_delivery_date = Date.parse("14/02/2019")
    @cumulative_data = getCumulativeFlowData   
    @title = CONFIG['TITLE']
    @type = 'AreaChart'
    @stacked = true
    @open_tickets = @cumulative_data.last[2..-1].sum
    @closed_tickets = @cumulative_data.last[1]
    data = getThroughputData
    throughput = data.last.last
    @throughput = data.last.last.round(2)    
    @work_days_remaining = -xmas_holidays + (Date.today..target_delivery_date).count {|d| (1..5).include?(d.wday)}    
    required_throughput = @open_tickets.to_f / @work_days_remaining
    work_days_required = throughput * @open_tickets    
    days_required = (work_days_required + (work_days_required*2/7)).round
    projected_delivery_date = today + days_required + xmas_holidays
    @work_days_required = (work_days_required).round
    @projected_delivery_date = projected_delivery_date.iso8601
    @target_delivery_date = target_delivery_date.iso8601
    @required_throughput = required_throughput.round(2)
    @warn = projected_delivery_date > target_delivery_date
    @colors = CONFIG['COLORS']
    
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
    erb :chart
  end

  get '/throughput' do
    $ROUTE = request.path_info 
    @data  = getThroughputData
    @stacked = false
    @title = 'Throughput'
    @type = 'ComboChart'
    erb :chart
  end

  def getThroughputData()
    data = getData(['TIME'].concat(CONFIG['THROUGHPUT_MAP']))    
    data.each_with_index do |d,i|
      avg = data[1..i].map {|row| row[1]}.inject(:+).to_f / (i)
      if i == 0
        data[i][2] = 'AVERAGE'
      else
        data[i][2] = avg
      end
    end

    return data
  end

  def getCumulativeFlowData()    
    data = getData(['TIME'].concat(CONFIG['CUMULATIVE_MAP']))    

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
            current[index] = $PROJECT_DATA[d.iso8601][key] || 0
          else
            current[index] = 0
          end 
        end
      end
      response << current     
    end
    return response
  end  
end


