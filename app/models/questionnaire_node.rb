class QuestionnaireNode < Node
  belongs_to :questionnaire, class_name: 'Questionnaire', foreign_key: 'node_object_id', inverse_of: false
  belongs_to :node_object, class_name: 'Questionnaire', foreign_key: 'node_object_id', inverse_of: false

  def self.table
  end

  def self.get(sortvar = nil, sortorder = nil, user_id = nil, show = nil, parent_id = nil, _search = nil)

  end

  def get_name
  end


  def get_instructor_id
  end

  def private?
  end

  def get_creation_date
  end

  def get_modified_date
  end

  def is_leaf
    true
  end
end