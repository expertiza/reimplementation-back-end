module FileHelper

  # replace invalid characters with underscore
  #    valid: period
  #           underscore
  #           forward slash
  #           alphanumeric characters
  def self.clean_path(file_name)
    new_str = file_name.gsub(%r{[^\w\.\_/]}, '_')
    new_str.tr("'", '_')
  end

  # Removes any extension or paths from file_name
  # Also removes for invalid characters in filename
  def self.sanitize_filename(file_name)
    just_filename = File.basename(file_name)
    FileHelper.clean_path(just_filename)
  end

  # Moves file from old location to a new location
  def self.move_file(old_loc, new_loc)
    new_dir, filename = File.split(new_loc)
    new_dir = FileHelper.clean_path(new_dir)

    FileHelper.create_directory_from_path(new_dir)
    FileUtils.mv old_loc, new_dir + filename
  end

  # Removes parent directory '..' from folder path.
  def self.sanitize_folder(folder)
    folder.gsub('..', '')
  end

  # Creates a new directory on the specified path.
  def self.create_directory_from_path(path)
    FileUtils.mkdir_p(path) unless File.exist? path
  rescue StandardError => e
    raise 'An error occurred while creating this directory: ' + e.message
  end
end