class CreateWaitlists < ActiveRecord::Migration[7.0]
  def change
    create_table :waitlists do |t|

      t.timestamps
    end
  end
end
