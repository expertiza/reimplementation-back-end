class QuestionnaireTypeNode < FolderNode
  belongs_to :table, class_name: 'TreeFolder', foreign_key: 'node_object_id', inverse_of: false
  belongs_to :node_object, class_name: 'TreeFolder', inverse_of: false

  def self.get(_sortvar = nil, _sortorder = nil, _user_id = nil, _show = nil, _parent_id = nil, _search = nil)
  end

  def partial_name
  end

  def name
  end

  def children(sortvar = nil, sortorder = nil, user_id = nil, show = nil, _parent_id = nil, search = nil)
  end
end
