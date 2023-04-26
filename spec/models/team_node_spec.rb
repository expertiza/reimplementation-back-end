require "rails_helper"

describe TeamNode do
  let(:team_user_node) { FactoryBot.build(:team_user_node, id: 1) }
  let(:team_node) { FactoryBot.build(:team_node, id: 1) }
  let(:team) { FactoryBot.build(:team, id: 1, name: "test") }

  before(:each) do
    team_node.node_object_id = 1

    allow(Team).to receive(:find).with(1).and_return(team)
    allow(TeamUserNode).to receive(:get).with(1).and_return(team_user_node)


  end
  describe '#name(_ip_address = nil)' do
	 it 'The code defines a method called "get_name" with an optional parameter "_ip_address". It retrieves the name of a team by finding it in the database using the "node_object_id" attribute. The method returns the name of the team.' do
     expect(team_node.name("test")).to eq("test")

   end
  end
  describe '#children(_sortvar = nil, _sortorder = nil, _user_id = nil, _parent_id = nil, _search = nil)' do
	 it 'The ruby code  defines a method called "get_children" which accepts four optional parameters: "_sortvar", "_sortorder", "_user_id", and "_parent_id". The method is currently empty and does not perform any actions. It simply returns the result of calling the "TeamUserNode.get" method with the argument "node_object_id". However, since "node_object_id" is not defined in the code provided, this method would raise an error if called without modification.' do
     expect(team_node.children.id).to eq(1)
   end
  end

end
