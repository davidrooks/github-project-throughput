require './ProjectModel.rb'

class ModelAccessor
    $projectModel = ProjectModel.new

    def getProjectModel
        return $projectModel
    end
end
