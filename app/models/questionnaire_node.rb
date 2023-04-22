class QuestionnaireNode < Node
  belongs_to :questionnaire, class_name: 'Questionnaire', foreign_key: 'node_object_id', inverse_of: false
  belongs_to :node_object, class_name: 'Questionnaire', foreign_key: 'node_object_id', inverse_of: false

  def self.get(sortvar = nil, sortorder = nil, user_id = nil, show = nil, parent_id = nil, _search = nil)

  end

  def name
  end


  def instructor_id
  end

  def private?
  end

  def creation_date
  end

  def modified_date
  end

  def self.leaf?
    true
  end
end
