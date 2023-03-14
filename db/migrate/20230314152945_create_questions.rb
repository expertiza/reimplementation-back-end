class CreateQuestions < ActiveRecord::Migration[7.0]
  def change
    create_table :questions do |t|
      t.text :txt
      t.integer :weight
      t.decimal :seq, precision: 6, scale: 2
      t.string :type
      t.string :size, default: ""
      t.string :alternatives
      t.boolean :break_before, default: true
      t.string :max_label, default: ""
      t.string :min_label, default: ""

      t.timestamps
    end
  end
end
