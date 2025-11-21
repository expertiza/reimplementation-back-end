# frozen_string_literal: true

class CreateParticipantsTeamsRelationship < ActiveRecord::Migration[7.0]
  def change
      add_reference :participants, :team, foreign_key: true
  end
end
