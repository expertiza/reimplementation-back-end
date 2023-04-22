class TeamNode < Node
  belongs_to :node_object, class_name: 'Team'

  def self.get(parent_id)
    nodes = Node.joins('INNER JOIN teams ON nodes.node_object_id = teams.id')
    .select('nodes.*')
    .where("nodes.type = 'TeamNode'")
nodes.where('teams.parent_id = ?', parent_id) if parent_id
  end

  def name(_ip_address = nil)
    Team.find(node_object_id).name
  end

  def children(_sortvar = nil, _sortorder = nil, _user_id = nil, _parent_id = nil, _search = nil)
    TeamUserNode.get(node_object_id)
  end
end
