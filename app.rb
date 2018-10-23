require 'json'
require 'time'
require 'rest-client'
require 'sinatra/base'
require 'tilt/erb'
require './project.rb'

class App < Sinatra::Base  
  get '/' do
    redirect '/cumulative-flow-diagram'
  end

  get '/data' do
    halt 200, {'Content-Type' => 'application/json'}, getData(['TIME','DONE', 'OPEN']).to_json
  end

  def active_page?(path='')
    request.path_info == '/' + path
  end

  get '/cumulative-flow-diagram' do
    @data  = getCumulativeFlowData
    @stacked = true
    @title = 'Cumulative Flow Diagram'
    @type = 'AreaChart'
    erb :chart
  end

  get '/work-in-progress' do
    @data  = getWIPData
    @stacked = false
    @title = 'Work in Progress vs Cycle Time'
    @type = 'AreaChart'
    erb :chart
  end 

  get '/throughput' do
    @data  = getThroughputData
    @stacked = false
    @title = 'Throughput'
    @type = 'ComboChart'
    erb :chart
  end

  def getThroughputData()
    data = getData(['TIME','THROUGHPUT'])
    avg = data[1..data.length+1].map {|row| row[1]}.inject(:+).to_f / (data.size-1)
    data.each_with_index do |d,i|
      if i == 0
        data[i][2] = 'AVERAGE'
      else
        data[i][2] = avg.to_i
      end
    end

    return data
  end

  def getWIPData()
    return getData(['TIME', 'CYCLE TIME','WIP'])
  end

  def getCumulativeFlowData()
    data = getData(['TIME','DONE', 'BLOCKED', 'READY FOR DESIGN', 'IN DESIGN', 'READY FOR DEV', 'IN DEVELOPMENT', 'IN REVIEW', 'IN TEST', 'TO DO'])    
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

    data = Project.new()    
    data = data.getData()

    min_date = Date.parse(data.keys.sort.first)
    max_date = Date.parse(data.keys.sort.last)

    current = []
    min_date.upto(max_date) { |d|
      if d.saturday? || d.sunday?
        next
      end
      if data.has_key? d.iso8601
        new = []
        format.each_with_index do |key, index|
          if key == 'TIME'
            new[0] = d.iso8601
          else            
            new[index] = data[d.iso8601][key] || 0
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


