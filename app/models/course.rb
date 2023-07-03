class Course < ApplicationRecord
  belongs_to :instructor, class_name: 'User', foreign_key: 'instructor_id'
  belongs_to :institution, foreign_key: 'institution_id'
  validates :name, presence: true
  validates :directory_path, presence: true
  has_many :ta_mappings, dependent: :destroy
  has_many :tas, through: :ta_mappings

  # returns the submission directory for the course
  def path
    raise 'Path can not be created as the course must be associated with an instructor.' if instructor_id.nil?
    Rails.root + '/' + Institution.find(institution_id).name.gsub(" ", "") + '/' + User.find(instructor_id).name.gsub(" ", "") + '/' + directory_path + '/'
  end

  # Add a Teaching Assistant to the course
  def add_ta(user)
    if user.nil?
      return { success: false, message: "The user with id #{user.id} does not exist" }
    elsif TaMapping.exists?(ta_id: user.id, course_id: id)
      return { success: false, message: "The user with id #{user.id} is already a TA for this course." }
    else
      ta_mapping = TaMapping.create(ta_id: user.id, course_id: id)
      user.update(role: Role::TEACHING_ASSISTANT)
      if ta_mapping.save
        return { success: true, data: ta_mapping.slice(:course_id, :ta_id) }
      else
        return { success: false, message: ta_mapping.errors }
      end
    end
  end
end
