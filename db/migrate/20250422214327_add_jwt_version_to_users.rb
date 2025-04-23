class AddJwtVersionToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :jwt_version, :string
  end
end
