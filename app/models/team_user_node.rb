class TeamUserNode < Node
  belongs_to :node_object, class_name: 'TeamsUser'

  def name(ip_address = nil)
  end

  def self.get(parent_id)
  end

  def self.leaf?
    true
  end
end
