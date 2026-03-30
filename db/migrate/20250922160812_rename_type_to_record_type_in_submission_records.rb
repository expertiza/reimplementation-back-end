class RenameTypeToRecordTypeInSubmissionRecords < ActiveRecord::Migration[7.0]
  def change
    # If the old column :type exists, rename it to :record_type (avoid STI conflicts)
    if column_exists?(:submission_records, :type)
      rename_column :submission_records, :type, :record_type
    else
      add_column :submission_records, :record_type, :string
    end

    # make content a text field to store longer file paths or URLs
    change_column :submission_records, :content, :text if column_exists?(:submission_records, :content)
  end
end
