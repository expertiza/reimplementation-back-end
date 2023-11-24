class ResponseMap < ApplicationRecord
    # 'reviewer_id' points to the User who is the instructor.
    belongs_to :reviewer, class_name: 'User', foreign_key: 'reviewer_id', optional: true
    # 'reviewee_id' (or 'user_id' if 'reviewee_id' is not needed) points to the User who is the student.
    belongs_to :reviewee, class_name: 'User', foreign_key: 'reviewee_id', optional: true
    # 'reviewed_object_id' points to the Questionnaire, so the association should match this.
    belongs_to :questionnaire, foreign_key: 'reviewed_object_id', optional: true
    has_many :responses
    validates :reviewee_id, uniqueness: { scope: :reviewed_object_id,
                                          message: "is already assigned to this questionnaire" }
end


# Stuff from the previous students that would cause errors, need to see about reimplementing it ???
#
#
# has_many :response, foreign_key: 'map_id', dependent: :destroy, inverse_of: false
# belongs_to :student, class_name: 'User', foreign_key: 'student_id'
# belongs_to :reviewer, class_name: 'Participant', foreign_key: 'reviewer_id', inverse_of: false
# belongs_to :reviewee, class_name: 'Participant', foreign_key: 'reviewee_id', inverse_of: false
# belongs_to :assignment, class_name: 'Assignment', foreign_key: 'reviewed_object_id', inverse_of: false
#
# alias map_id id
#
# # returns the assignment related to the response map
# def response_assignment
#   return Participant.find(self.reviewer_id).assignment
# end
#
# def self.assessments_for(team)
#   responses = []
#   # stime = Time.now
#   if team
#     array_sort = []
#     sort_to = []
#     maps = where(reviewee_id: team.id)
#     maps.each do |map|
#       next if map.response.empty?
#
#       all_resp = Response.where(map_id: map.map_id).last
#       if map.type.eql?('ReviewResponseMap')
#         # If its ReviewResponseMap then only consider those response which are submitted.
#         array_sort << all_resp if all_resp.is_submitted
#       else
#         array_sort << all_resp
#       end
#       # sort all versions in descending order and get the latest one.
#       sort_to = array_sort.sort # { |m1, m2| (m1.updated_at and m2.updated_at) ? m2.updated_at <=> m1.updated_at : (m1.version_num ? -1 : 1) }
#       responses << sort_to[0] unless sort_to[0].nil?
#       array_sort.clear
#       sort_to.clear
#     end
#     responses = responses.sort { |a, b| a.map.reviewer.fullname <=> b.map.reviewer.fullname }
#   end
#   responses
# end

