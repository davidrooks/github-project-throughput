# Language: Ruby, Level: Level 3

class GithubProcessor

    def getDataJson(format)
        response = []
        min_date = Date.parse($modelAccessor.getProjectModel.getIssuesWithSinglePoint.keys.sort.first)
        max_date = Date.today

        min_date.upto(max_date) do |d|
            if d.saturday? || d.sunday?
                next
            end
            current = {}
            format.each_with_index do |key, index|
                current = {"DATE": d.iso8601}
                if $modelAccessor.getProjectModel.getIssuesWithSinglePoint.has_key? d.iso8601
                    format.each_with_index do |k, i|
                        current[format[i].upcase] = $modelAccessor.getProjectModel.getIssuesWithSinglePoint[d.iso8601][format[i].upcase] || 0
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

    def getDataJsonWithPoints(format)
        response = []

        min_date = Date.parse($modelAccessor.getProjectModel.getTransformedIssuesWithSinglePoint.keys.sort.first)
        max_date = Date.today

        min_date.upto(max_date) do |d|
            if d.saturday? || d.sunday?
                next
            end
            current = {}
            format.each_with_index do |key, index|
                current = {"DATE": d.iso8601}
                if $modelAccessor.getProjectModel.getTransformedIssuesWithSinglePoint.has_key? d.iso8601
                    format.each_with_index do |k, i|
                        current[format[i].upcase] = $modelAccessor.getProjectModel.getTransformedIssuesWithSinglePoint[d.iso8601][format[i].upcase] || 0
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

        min_date = Date.parse($modelAccessor.getProjectModel.getIssuesWithSinglePoint.keys.sort.first)
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
                    if $modelAccessor.getProjectModel.getIssuesWithSinglePoint.has_key? d.iso8601
                        current[index] = $modelAccessor.getProjectModel.getIssuesWithSinglePoint[d.iso8601][key.upcase] || 0
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
