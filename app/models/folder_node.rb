class FolderNode < Node
  belongs_to :folder, class_name: 'TreeFolder', foreign_key: 'node_object_id'
  belongs_to :node_object, class_name: 'TreeFolder'

  def self.get(_sortvar = nil, _sortorder = nil, _user_id = nil, _show = nil, _parent_id = nil, _search = nil)
  end

  def name
  end

  def partial_name

  end

  def child_type
  end

  def children(sortvar = nil, sortorder = nil, user_id = nil, show = nil, parent_id = nil, search = nil)

  end
end
