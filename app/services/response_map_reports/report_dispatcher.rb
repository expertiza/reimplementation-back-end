# frozen_string_literal: true

module ResponseMapReports
  # Resolves report type and delegates report generation to visitor methods.
  class ReportDispatcher
    TYPE_MAP = {
      'reviewresponsemap' => ReviewResponseMap,
      'feedbackresponsemap' => FeedbackResponseMap,
      'teammatereviewresponseMap' => TeammateReviewResponseMap
    }.freeze

    def initialize(visitor = ReportVisitor.new)
      @visitor = visitor
    end

    def call(assignment_id:, type: nil)
      map_class = resolve_map_class(type)
      map_class.accept_report_visitor(@visitor, assignment_id)
    end

    private

    def resolve_map_class(type)
      return ResponseMap if type.blank?

      normalized_type = type.to_s.downcase
      TYPE_MAP[normalized_type] || ResponseMap
    end
  end
end
