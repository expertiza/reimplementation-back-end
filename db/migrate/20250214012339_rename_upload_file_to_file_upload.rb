class RenameUploadFileToFileUpload < ActiveRecord::Migration[7.0]
  def change
    rename_table :upload_files, :file_uploads
  end
end
