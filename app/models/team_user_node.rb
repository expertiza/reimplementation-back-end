class TeamUserNode < Node
  belongs_to :node_object, class_name: 'TeamsUser'

  def self.table
  end

  def get_name(ip_address = nil)
  end

  def self.get(parent_id)
  end

  def is_leaf
    true
  end
end
