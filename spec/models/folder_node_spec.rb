require 'rails_helper'

describe FolderNode do
  let(:folder_node) { FactoryBot.build(:folder_node, parent_id: 2) }
  let(:folder_node2) { FactoryBot.build(:folder_node, name: "ABC", id: 1) }
  let(:questionnaire) { FactoryBot.build(:questionnaire) }

  describe '#get_name' do
	 it 'The code defines a method called "get_name" which takes no arguments. Within the method, it calls the "find" method on the TreeFolder class, passing in the value of a variable called "node_object_id". It then retrieves the "name" attribute of the resulting object and returns it. In summary, the code retrieves the name of a TreeFolder object based on its ID.' do
     tree_folder = double('TreeFolder', id: 1, name: "test")

     allow(TreeFolder).to receive(:find).with(1).and_return(tree_folder)
     expect(folder_node.name).to eq("test")
   end
  end
  describe '#get_partial_name' do
	 it 'The Ruby code  defines a method called `get_partial_name` that returns a string value. If the objects `parent_id` attribute is `nil`, the method returns the result of concatenating the lowercase version of the objects `name` attribute with the string "_folder_actions".If the objects `parent_id` attribute is not `nil`, the method returns the string "questionnaire_types_actions".' do
     tree_folder = double('TreeFolder', id: 1, name: "ABC")

     allow(TreeFolder).to receive(:find).with(1).and_return(tree_folder)

     expect(folder_node2.partial_name).to eq("abc_folder_actions")
     end
  end
  describe '#get_child_type' do
	 it 'The Ruby code  defines a method called `get_child_type` which finds a folder in a tree structure using its `node_object_id` and returns the `child_type` of that folder. The `child_type` is likely a property or attribute of the folder that indicates the type of child nodes that can be added to it in the tree structure.' do
     tree_folder = double('TreeFolder', id: 1, child_type: "test")

     allow(TreeFolder).to receive(:find).with(1).and_return(tree_folder)
     expect(folder_node.child_type).to eq("test")
     
   end 
  end
end
