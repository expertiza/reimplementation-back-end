class MentoredTeam < AssignmentTeam
  belongs_to :mentor, class_name: 'User'

  validates :mentor, presence: true
  validate :type_must_be_mentored_team
  validate :mentor_must_have_mentor_role

  def add_member(user)
    return false if user == mentor
    super(user)
  end

  def assign_mentor(user)
    return false unless user.role&.name&.downcase&.include?('mentor')
    self.mentor = user
    save
  end

  def remove_mentor
    self.mentor = nil
    save
  end

  private

  def type_must_be_mentored_team
    errors.add(:type, 'must be MentoredTeam') unless type == 'MentoredTeam'
  end

  def mentor_must_have_mentor_role
    return unless mentor
    errors.add(:mentor, 'must have mentor role') unless mentor.role&.name&.downcase&.include?('mentor')
  end
end 