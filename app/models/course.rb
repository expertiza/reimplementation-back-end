class Course < ApplicationRecord
  belongs_to :instructor, class_name: 'User', foreign_key: 'instructor_id'
  belongs_to :institution, foreign_key: 'institution_id'
  validates :name, presence: true
  validates :directory_path, presence: true
  has_many :ta_mappings, dependent: :destroy
  has_many :tas, through: :ta_mappings

  #returns the submission directory for the course
  def path

  end

  #returns tas associated with the course
  def get_tas

  end

end
