class ChangeInvitationFromIdForeignKey < ActiveRecord::Migration[7.0]
  # This migration is an intentional no-op.
  #
  # Its original intent was to re-point invitations.from_id's foreign key onto
  # teams, but that reference was abandoned: the Invitation model models
  # from_id / to_id as references to participants, not teams,
  #   belongs_to :from_participant, class_name: 'AssignmentParticipant', foreign_key: 'from_id'
  #   belongs_to :to_participant,  class_name: 'AssignmentParticipant', foreign_key: 'to_id'
  #   # belongs_to :from_team, ... (commented out)
  # and create_invitations (20230412020156) gives these columns only plain
  # indexes with no foreign key at all. The old `remove_foreign_key :invitations,
  # column: :from_id` therefore found nothing to remove and aborted from-scratch
  # builds with "Table 'invitations' has no foreign key for {column: :from_id}";
  # and `add_foreign_key ... :teams` would install a constraint that contradicts
  # the model. Re-implementation foreign keys on these columns (if any) are part
  # of the canonical schema, not something this migration should create, so both
  # operations are dropped.
  def change; end
end
