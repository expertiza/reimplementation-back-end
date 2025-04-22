class BookmarkRatingResponseMap < ReviewResponseMap
  belongs_to :reviewee, class_name: 'Bookmark', foreign_key: 'reviewee_id'
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'reviewed_object_id'

  def questionnaire
    assignment.questionnaires.where(type: 'BookmarkRatingResponseMap')
  end

  def self.bookmark_response_report(assignment_id)
    BookmarkRatingResponseMap.select('DISTINCT reviewer_id').where('reviewed_object_id = ?', id)
  end
end