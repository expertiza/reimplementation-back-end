class QuestionnaireNode < Node
  belongs_to :questionnaire, class_name: 'Questionnaire', foreign_key: 'node_object_id', inverse_of: false
  belongs_to :node_object, class_name: 'Questionnaire', foreign_key: 'node_object_id', inverse_of: false

  def self.get(sortvar = nil, sortorder = nil, user_id = nil, show = nil, parent_id = nil)
    conditions = get_privacy_clause(show, user_id)
    if parent_id
      name = TreeFolder.find(parent_id).name + 'Questionnaire'
      name.gsub!(/[^\w]/, '')
      conditions += " and questionnaires.type = \"#{name}\""
    end
      sortvar = 'name' if sortvar.nil? || (sortvar == 'directory_path')
      sortorder ||= 'ASC'
      (includes(:questionnaire).where([conditions, values]).order("questionnaires.#{sortvar} #{sortorder}") if Questionnaire.column_names.include?(sortvar) &&
      %w[ASC DESC asc desc].include?(sortorder))
  end

  def self.get_privacy_clause(show = nil, user_id = nil)
    query_user = User.find_by(id: user_id)

    if query_user && query_user.teaching_assistant?
      clause = "questionnaires.instructor_id in (#{Ta.get_mapped_instructor_ids(user_id)})"
    else
      clause = "questionnaires.instructor_id = #{user_id}"
    end

    show ? clause : "(questionnaires.private = 0 or #{clause})"
  end

  def cached_questionnaire_lookup(parameter)
    if !@cached_questionnaire
      @cached_questionnaire = Questionnaire.find_by(id: node_object_id)
    end
    @cached_questionnaire.try(parameter)
  end


  def name
    cached_questionnaire_lookup(:name)
  end

  def instructor_id
    cached_questionnaire_lookup(:instructor_id)
  end

  def private?
    cached_assignment_lookup(:private)
  end

  def creation_date
    cached_questionnaire_lookup(:created_at)
  end

  def modified_date
    cached_questionnaire_lookup(:updated_at)
  end

  def self.leaf?
    true
  end
end
