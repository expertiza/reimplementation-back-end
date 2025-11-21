# frozen_string_literal: true

class AddTypeToParticipants < ActiveRecord::Migration[8.0]
  def change
    add_column :participants, :type, :string, null: false
  end
end
