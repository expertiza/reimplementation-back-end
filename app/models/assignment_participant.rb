require 'uri'
require 'yaml'
# Code Review: Notice that Participant overloads two different concepts:
#              contribution and participant (see fields of the participant table).
#              Consider creating a new table called contributions.
#
# Alias methods exist in this class which append 'get_' to many method names. Use
# the idiomatic ruby method names (without get_)

class AssignmentParticipant < Participant
  belongs_to  :assignment, class_name: 'Assignment', foreign_key: 'assignment_id'
  has_many    :review_mappings, class_name: 'ReviewResponseMap', foreign_key: 'reviewee_id'
  has_many    :response_maps, foreign_key: 'reviewee_id'
  belongs_to :user
  validates :handle, presence: true

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
end