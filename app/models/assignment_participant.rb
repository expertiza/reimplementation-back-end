# frozen_string_literal: true

class AssignmentParticipant < Participant
  has_many :sent_invitations, class_name: 'Invitation', foreign_key: 'from_id'
  has_many :review_mappings, class_name: 'ReviewResponseMap', foreign_key: 'reviewee_id'
  has_many :response_maps, foreign_key: 'reviewee_id'
  has_many :sent_invitations, class_name: 'Invitation', foreign_key: 'from_id'
  belongs_to :duty, optional: true
  belongs_to :user
  validates :handle, presence: true

  # Delegation methods to avoid Law of Demeter violations
  delegate :name, to: :user, prefix: true, allow_nil: true
  delegate :id, to: :team, prefix: true, allow_nil: true
  delegate :id, to: :assignment, prefix: true, allow_nil: true
  delegate :path, to: :team, prefix: true, allow_nil: true

  # Fetches the team for specific participant
  def team
    AssignmentTeam.team(self)
  end

  # Fetches Assignment Directory.
  def dir_path
    assignment.try :directory_path
  end

  # Gets the student directory path
  def path
    "#{assignment.path}/#{team.directory_num}"
  end
    
  def retract_sent_invitations
    sent_invitations.each(&:retract)
  end

  def set_handle
    self.handle = if user.handle.nil? || (user.handle == '')
                    user.name
                  elsif Participant.exists?(assignment_id: assignment.id, handle: user.handle)
                    user.name
                  else
                    user.handle
                  end
    self.save
  end

  def retract_sent_invitations
    sent_invitations.each(&:retract)
  end

  def aggregate_teammate_review_grade(teammate_review_mappings)
    ResponseMap.compute_average_reviewer_score(teammate_review_mappings)
  end

  # Returns a hash of { course_name => [teammate_fullnames] } for all
  # assignment teams the user has been part of.
  def self.all_teammates(user)
    result = {}
    user.teams.each do |team|
      next unless team.is_a?(AssignmentTeam)
      assignment = Assignment.find_by(id: team.parent_id)
      next if assignment.nil? || assignment[:is_calibrated]

      course_name = assignment.course&.name || 'Unknown Course'
      teammates = team.users.where.not(id: user.id).map(&:full_name)
      next if teammates.empty?

      result[course_name] ||= []
      result[course_name] |= teammates
    end
    result.transform_values(&:sort).sort.to_h
  end

  # Builds a unified timeline of due dates and submitted review activity for this participant.
  # Due dates are labeled with round info; peer reviews and author feedback appear as timestamped entries.
  def timeline_events
    timeline = []

    DueDate.fetch_due_dates(assignment).each do |due_date|
      timeline << {
        'id'    => nil,
        'name'  => due_date.round && due_date.round > 1 ? "#{due_date.deadline_name} deadline (round #{due_date.round})" : "#{due_date.deadline_name} deadline",
        'date'  => due_date.due_at.iso8601,
        'type'  => due_date.deadline_type_id,
        'round' => due_date.round
      }
    end

    ReviewResponseMap.where(reviewer_id: id).find_each do |map|
      Response.where(map_id: map.id, is_submitted: true).order(updated_at: :desc).each do |response|
        timeline << {
          'id'    => response.id,
          'name'  => "Round #{response.round} peer review",
          'date'  => response.updated_at.iso8601,
          'type'  => ExpertizaConstants::DeadlineTypes::REVIEW,
          'round' => response.round
        }
      end
    end

    FeedbackResponseMap.where(reviewer_id: id).find_each do |map|
      response = Response.where(map_id: map.id, is_submitted: true).order(updated_at: :desc).first
      next if response.nil?

      timeline << {
        'id'    => response.id,
        'name'  => 'Author feedback',
        'date'  => response.updated_at.iso8601,
        'type'  => nil,
        'round' => response.round
      }
    end

    timeline.sort_by { |item| item['date'] }
  end
end
