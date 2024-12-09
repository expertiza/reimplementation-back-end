class AddSkippableToQuestions < ActiveRecord::Migration[7.0]
  def change
    add_column :questions, :skippable, :boolean, default: true
  end
end
