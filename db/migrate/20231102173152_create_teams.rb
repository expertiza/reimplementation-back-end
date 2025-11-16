# frozen_string_literal: true

class CreateTeams < ActiveRecord::Migration[8.0]
  def change
    create_table :teams do |t|
      t.string :name, null: false
      t.integer :parent_id, index: true
      t.string :type, null: false

      t.text    :comments_for_advertisement
      t.boolean :advertise_for_partner, null: false, default: false
      t.text    :submitted_hyperlinks
      t.integer :directory_num
      t.integer :grade_for_submission
      t.text    :comment_for_submission

      t.timestamps
    end

    add_index :teams, :type
  end
end 
