require "rails_helper"

describe TeamUserNode do
  let(:team_user_node) { FactoryBot.build(:team_user_node, id: 1) }
  let(:teams_user) { FactoryBot.build(:teams_user, id: 1) }
  let(:user1) { User.new name: 'test', fullname: 'abc bbc', email: 'abcbbc@gmail.com', password: '123456789', password_confirmation: '123456789' }

  before(:each) do
    team_user_node.node_object_id = 1

    allow(teams_user).to receive(:name).and_return("test")
    allow(TeamsUser).to receive(:find).with(1).and_return(teams_user)

  end
  describe '#get_name(ip_address = nil)' do
	   it 'The code defines a method called "get_name" that takes an optional parameter "ip_address" (which defaults to nil). The method uses the "node_object_id" to find a TeamsUser object, and then calls the "name" method on that object, passing in the "ip_address" parameter. The resulting value of the "name" method call is returned by the "get_name" method.' do
         expect(team_user_node.name("test")).to eq("test")
       end 
  end
  describe '#self.get(parent_id)' do
	   it 'The code defines a class method called `get` for a class (presumably called `Node`). The method takes one argument, `parent_id`. The method performs a database query using ActiveRecord, joining the `nodes` table with the `teams_users` table on the condition that the `node_object_id` field in `nodes` matches the `id` field in `teams_users`. It selects all fields from `nodes`. If `parent_id` is provided, the method filters the results to only include rows where the `team_id` field in `teams_users` matches `parent_id`. The method then returns the resulting ActiveRecord relation object.'
  end
  describe '#is_leaf' do
	    it 'The code defines a method named "is_leaf" that returns the boolean value "true". However, there is a syntax error in the code as there is an extra "end" keyword after the method definition. The correct code should be:```def is_leaf  trueend```This code defines a method named "is_leaf" that always returns "true".' do
        expect(TeamUserNode.leaf?).to eq(true)
        
      end
   end
end
