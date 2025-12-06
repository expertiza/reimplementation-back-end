module FileHelper
  extend self
  # Replace invalid characters with underscore
  def clean_path(file_name)
    file_name.to_s.gsub(%r{[^\w\.\_/]}, '_').tr("'", '_')
  end

  # Removes any extension or paths from file_name
  def sanitize_filename(file_name)
    just_filename = File.basename(file_name)
    clean_path(just_filename)
  end

  # Make methods available as module methods
  module_function :clean_path, :sanitize_filename

  # Moves file from old location to a new location
  def move_file(old_loc, new_loc)
    new_dir, filename = File.split(new_loc)
    new_dir = clean_path(new_dir)
    filename = sanitize_filename(filename)

    create_directory_from_path(new_dir)
    FileUtils.mv old_loc, File.join(new_dir, filename)
  end

  # Removes parent directory '..' from folder path
  def sanitize_folder(folder)
    folder.gsub('..', '')
  end

  # Creates a new directory on the specified path
  def create_directory_from_path(path)
    FileUtils.mkdir_p(path) unless File.exist?(path)
  rescue StandardError => e
    raise "An error occurred while creating this directory: #{e.message}"
  end
end
