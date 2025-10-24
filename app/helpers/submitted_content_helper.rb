module SubmittedContentHelper
  include FileHelper

  # Unzipping the requested file in a new directory
  def self.unzip_file(file_name, unzip_dir, should_delete)
    unless File.exist?(file_name)
      return { error: "File #{file_name} does not exist" }
    end

    Zip::File.open(file_name) do |zf|
      zf.each do |e|
        extract_entry(e, unzip_dir)
      end
    end

    File.delete(file_name) if should_delete
    { message: "Unzipped successfully" }
  end

  private

  # Extract all the subfolders in the zipped file
  def self.extract_entry(e, unzip_dir)
    safe_name = FileHelper.sanitize_filename(e.name)
    file_path = File.join(unzip_dir, safe_name)
    FileUtils.mkdir_p(File.dirname(file_path))
    e.extract(file_path) { true } # overwrite if exists
  end

  def get_filename
    "#{params[:directories][params[:chk_files]]}/#{params[:filenames][params[:chk_files]]}"
  end

  def handle_file_operation_error(operation)
    yield
  rescue StandardError => e
    render json: { error: "There was a problem #{operation} the file: #{e.message}"}, status: :unprocessable_entity
  end

  def check_extension_integrity(original_filename)
    allowed_extensions = %w[pdf png jpeg jpg zip tar gz 7z odt docx md rb mp4 txt]
    file_extension = original_filename&.split('.')&.last&.downcase
    allowed_extensions.include?(file_extension)
  end

  def check_content_size(file, size_mb)
    file.size <= size_mb * 1024 * 1024
  end

  def file_type(file_name)
    File.extname(file_name).delete('.')
  end

  def move_selected_file
    old_filename = get_filename
    new_location = File.join(@participant.dir_path, params[:faction][:move])

    handle_file_operation_error('moving') do
      FileHelper.move_file(old_filename, new_location)
      render json: { message: "The file was successfully moved." }, status: :ok
      return
    end
  end

  def rename_selected_file
    old_filename = get_filename
    new_filename = File.join(params[:directories][params[:chk_files]],
                             FileHelper.sanitize_filename(params[:faction][:rename]))

    handle_file_operation_error('renaming') do
      if File.exist?(new_filename)
        render json: { error: "A file already exists with that name." }, status: :conflict
        return
      end
      File.rename(old_filename, new_filename)
      render json: { message: "File renamed successfully." }, status: :ok
      return
    end
  end

  def copy_selected_file
    old_filename = get_filename
    new_filename = File.join(params[:directories][params[:chk_files]],
                             FileHelper.sanitize_filename(params[:faction][:copy]))

    handle_file_operation_error('copying') do
      if File.exist?(new_filename)
        render json: { error: 'A file with this name already exists.' }, status: :conflict
        return
      end
      unless File.exist?(old_filename)
        render json: { error: 'The referenced file does not exist.' }, status: :not_found
        return
      end

      FileUtils.cp_r(old_filename, new_filename)
      render json: { message: 'File copied successfully.' }, status: :ok
      return
    end
  end

  def delete_selected_files
    handle_file_operation_error('deleting') do
      deleted_files = []

      Array(params[:chk_files]).each do |idx|
        file_path = File.join(params[:directories][idx], params[:filenames][idx])

        if File.exist?(file_path)
          FileUtils.rm_rf(file_path) # removes file or directory recursively
          deleted_files << file_path
        else
          render json: { error: "File #{file_path} does not exist." }, status: :not_found
          return
        end
      end

      render json: { message: "Files deleted successfully.", files: deleted_files }, status: :no_content
    end
  end

  def create_new_folder
    location = File.join(@participant.dir_path, params[:faction][:create])
    handle_file_operation_error('creating directory') do
      FileHelper.create_directory_from_path(location)
      render json: { message: "Directory '#{params[:faction][:create]}' created successfully." }, status: :created
    end
  end
end
