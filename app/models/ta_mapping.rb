class TaMapping < ApplicationRecord
  belongs_to :course
  belongs_to :ta

  #Returns course ids of the TA
  def self.get_course_ids(user_id)
    ta_mapping = TaMapping.find_by(user_id: user_id)
    ta_mapping&.course_id
  end

  #Returns courses of the TA
  def self.get_courses(user_id)
    course_ids = get_course_ids(user_id)

    return Course.none unless course_ids  # Return Course.none if course_ids is nil

    Course.where(id: course_ids)
  end
end
