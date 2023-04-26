require "rails_helper"

describe AssignmentNode do
  let(:assignment) { FactoryBot.build(:assignment,id: 1)}
  let(:assignment_node) { FactoryBot.build(:assignment_node, id: 1)}
  
  before(:each) do
    assignment_node.node_object_id = 1
    allow(assignment).to receive(:name).and_return("test")
    end
  end
  describe '#leaf' do
	 it 'The code defines a method named "is_leaf" that always returns a boolean value of true.' do
     expect(AssignmentNode.leaf?).to eq(true)
   end 
  end
  describe '#name' do
	 it 'The code defines a method called "get_name". The method first checks if an instance variable called "@assign_node" exists, and if it does, it returns the value of its "name" attribute. If "@assign_node" is nil, it uses the "try" method to attempt to find an "Assignment" object by its ID, which is stored in a variable called "node_object_id". If an "Assignment" object is found, it returns its "name" attribute. If no "Assignment" object is found, it returns nil.' do
     expect(assignment_node.name).to eq("test")
     end
  end

end
