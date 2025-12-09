class AddDateFormatPrefToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :date_format_pref, :string, default: "mm/dd/yyyy"
  end
end
