class AssignmentTeam < Team
  #empty model added
  def self.team(participant)
    #dummy method added

  end

  def hyperlinks
    submitted_hyperlinks.blank? ? [] : YAML.safe_load(submitted_hyperlinks)
  end
  # Get the path of the team directory
  def path
    assignment.path + '/' + directory_num.to_s
  end

  # Set the directory num for this team
  def set_student_directory_num
    return if directory_num && (directory_num >= 0)

    max_num = AssignmentTeam.where(parent_id: parent_id).order('directory_num desc').first.directory_num
    dir_num = max_num ? max_num + 1 : 0
    update_attributes(directory_num: dir_num)
  end
end