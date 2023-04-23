class TeamUserNode < Node
  belongs_to :node_object, class_name: 'TeamsUser'

  def name(ip_address = nil)
    TeamsUser.find(node_object_id).name(ip_address)
  end

  def self.get(parent_id)
    nodes = Node.joins('INNER JOIN teams_users ON nodes.node_object_id = teams_users.id')
    .select('nodes.*')
    .where("nodes.type = 'TeamUserNode'")
    nodes.where('teams_users.team_id = ?', parent_id) if parent_id
  end

  def self.leaf?
    true
  end
end
