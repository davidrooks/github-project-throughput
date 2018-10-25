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
  PROJECT_DATA = PROJECT.getData()
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
    target_delivery_date = Date.parse("14/02/2019")
    @cumulative_data = getCumulativeFlowData    
    @type = 'AreaChart'
    @stacked = true
    @open_tickets = @cumulative_data.last[2..-1].sum
    @closed_tickets = @cumulative_data.last[1]
    data = getThroughputData
    throughput = data.last.last
    @throughput = data.last.last.round(2)
    @work_days_remaining = -10 + (Date.today..target_delivery_date).count {|d| (1..5).include?(d.wday)}    
    required_throughput = @open_tickets.to_f / @work_days_remaining
    projected_work_days_remaining = throughput * @open_tickets    
    projected_days_remaining = (projected_work_days_remaining + (projected_work_days_remaining*2/7)).round
    projected_delivery_date = today + projected_days_remaining
    @projected_delivery_date = projected_delivery_date.iso8601
    @target_delivery_date = target_delivery_date.iso8601
    @required_throughput = required_throughput.round(2)
    @warn = projected_delivery_date > target_delivery_date
    
    erb :index
  end

  get '/refresh' do    
    PROJECT_DATA = PROJECT.refresh
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
  
    min_date = Date.parse(PROJECT_DATA.keys.sort.first)
    max_date = Date.parse(PROJECT_DATA.keys.sort.last)

    current = []
    min_date.upto(max_date) { |d|
      if d.saturday? || d.sunday?
        next
      end
      if PROJECT_DATA.has_key? d.iso8601
        new = []
        format.each_with_index do |key, index|
          if key == 'TIME'
            new[0] = d.iso8601
          else            
            new[index] = PROJECT_DATA[d.iso8601][key] || 0
          end
        end
        response << new
        current = new
      else
        response << current
      end
    }
    return response
  end  
end


