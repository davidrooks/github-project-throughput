# Language: Ruby, Level: Level 3
require 'singleton'

class ProjectModel
    include Singleton

    attr_accessor :board
    attr_accessor :issue_with_points
    attr_accessor :issues_with_single_point
    attr_accessor :issue_transformed_with_points

    def getBoard
        return self.board
    end

    def getIssueWithPoints
        return self.issue_with_points
    end

    def getIssuesWithSinglePoint
        return self.issues_with_single_point
    end

    def getTransformedIssuesWithSinglePoint
        return self.issue_transformed_with_points
    end
end
