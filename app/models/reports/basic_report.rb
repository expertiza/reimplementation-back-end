# frozen_string_literal: true

module Reports
  # Basic report: minimal reportable metadata.
  # Used as a fallback when no specific report type is requested.
  # No streaming needed — all data comes from the already-loaded reportable.
  class BasicReport
    # Factory method for assignment-scoped reports.
    def self.for_assignment(assignment)
      new(assignment)
    end

    # Factory method for course-scoped reports.
    def self.for_course(course)
      new(course)
    end

    # @param reportable [Assignment, Course] the object the report is scoped to.
    def initialize(reportable)
      @reportable = reportable
    end

  def run
    {
      reportable: {
        id:                      @reportable.id,
        name:                    @reportable.name,
        num_review_rounds:       @reportable.num_review_rounds,
        varying_rubrics_by_round: @reportable.varying_rubrics_by_round?
      }
    }
  end
end
end
