class CreateAssignmentsDutiesAndDuties < ActiveRecord::Migration[8.0]
  def change
    unless table_exists?(:assignments_duties)
      create_table :assignments_duties,
                   charset: "utf8mb4",
                   collation: "utf8mb4_0900_ai_ci" do |t|
        t.bigint :assignment_id, null: false
        t.bigint :duty_id, null: false
        t.timestamps
      end

      add_index :assignments_duties, :assignment_id
      add_index :assignments_duties, :duty_id
    end

    unless table_exists?(:duties)
      create_table :duties,
                   charset: "utf8mb4",
                   collation: "utf8mb4_0900_ai_ci" do |t|
        t.string  :name
        t.boolean :private, default: false
        t.bigint  :instructor_id, null: false
        t.timestamps
      end

      add_index :duties, :instructor_id
    end

    add_foreign_key :assignments_duties, :assignments unless foreign_key_exists?(:assignments_duties, :assignments)
    add_foreign_key :assignments_duties, :duties unless foreign_key_exists?(:assignments_duties, :duties)
    add_foreign_key :duties, :users, column: :instructor_id unless foreign_key_exists?(:duties, :users)
  end
end