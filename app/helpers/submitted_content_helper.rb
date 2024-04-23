module SubmittedContentHelper
  include FileHelper
  # Installing RubyZip
  # run the command,  gem install rubyzip
  # restart the server
  # Unzipping the the requested file in a new directory.
  def self.unzip_file(file_name, unzip_dir, should_delete)
    # Checking if file exists.
    if File.exist?(file_name)
      render json: { message: "File #{file_name} does not exist" }, status: :bad_request
    end
    
    # begin unzipping.
    Zip::File.open(file_name) do |zf|
      zf.each do |e|
        extract_entry(e, unzip_dir)
      end
    end

    if should_delete
      # The zip file is no longer needed, so delete it
      File.delete(file_name)
    end
  end

  private

  # Extract all the subfolders in the zipped file
  def extract_entry(e, unzip_dir)
    safe_name = FileHelper.sanitize_filename(e.name)
    file_path = File.join(unzip_dir, safe_name)
    FileUtils.mkdir_p(File.dirname(file_path))
    zf.extract(e, file_path)
  end

  # Returns the entire path for the particular file name ()from params).
  def get_filename
    "#{params[:directories][params[:chk_files]]}/#{params[:filenames][params[:chk_files]]}"
  end

  # Generalize wrapper function to print Internal Server Errors for file operations
  def handle_file_operation_error(operation)
    yield
  rescue StandardError => e
    render json: { error: "There was a problem #{operation} the file: #{e.message}"}, status: :unprocessable_entity
  end

  # Checks if the file extension for the submitted file is acceptable or not.
  def check_extension_integrity(original_filename)
    allowed_extensions = %w[pdf png jpeg zip tar gz 7z odt docx md rb mp4 txt]
    file_extension = original_filename&.split('.')&.last&.downcase
    allowed_extensions.include?(file_extension)
  end

  # Checks the size of the file.
  # Calculated and compared in mb.
  def check_content_size(file, size)
    file.size <= size * 1024 * 1024
  end

  # Extract File Type from filename
  def file_type(file_name)
    File.extname(file_name).delete('.')
  end

  # Move the selected file
  def move_selected_file
    old_filename = get_filename
    new_location = File.join(@participant.dir_path, params[:faction][:move])
    handle_file_operation_error('moving') do
      FileHelper.move_file(old_filename, new_location)
      render json: { message: "The file was successfully moved from \"/#{params[:filenames][params[:chk_files]]}\" to \"/#{params[:faction][:move]}\""}, 
             status: :ok
      return
    end
  end

  # Rename the selected file.
  def rename_selected_file
    old_filename = get_filename
    new_filename = File.join(params[:directories][params[:chk_files]],
                             FileHelper.sanitize_filename(params[:faction][:rename]))
    handle_file_operation_error('renaming') do
      if File.exist?(new_filename)
        render json: { message: "A file already exists in this directory with the name \"#{params[:faction][:rename]}\"" },
               status: :conflict
        return
      end
      File.rename(old_filename, new_filename)
    end
  end

  # Copy selected file.
  def copy_selected_file
    old_filename = get_filename
    new_filename = File.join(params[:directories][params[:chk_files]],
                             FileHelper.sanitize_filename(params[:faction][:copy]))
    handle_file_operation_error('copying') do 
      if File.exist?(new_filename)
        render json: { message: 'A file with this name already exists. Please delete the existing file before copying.' },
               status: :bad_request
        return
      end
      unless File.exist?(old_filename)
        render json: { message: 'The referenced file does not exist.' }, status: :not_found
      end

      FileUtils.cp_r(old_filename, new_filename)
    end
  end

  # Create a New Folder.
  def create_new_folder
    location = File.join(@participant.dir_path, params[:faction][:create])
    handle_file_operation_error('creating directory') do
      FileHelper.create_directory_from_path(location)
      render json: { message: "The directory #{params[:faction][:create]} was created."}, status: :ok
    end
  end
end
