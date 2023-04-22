class TeamNode < Node
  belongs_to :node_object, class_name: 'Team'

  def self.get(parent_id)
  end

  def name(_ip_address = nil)
  end

  def children(_sortvar = nil, _sortorder = nil, _user_id = nil, _parent_id = nil, _search = nil)
  end
end
