class Badge < ApplicationRecord

  def self.get_id_from_name(badge_name)
    Badge.find_by(name: badge_name)&.id
  end

  def self.get_image_name_from_name(badge_name)
    Badge.find_by(name: badge_name)&.image_name
  end

  def self.upload_image(image_file)
    return '' unless image_file

    image_name = image_file.original_filename
    File.open(Rails.root.join('app', 'assets', 'images', 'badges', image_name), 'wb') do |file|
      file.write(image_file.read)
    end
    image_name
  end
end
