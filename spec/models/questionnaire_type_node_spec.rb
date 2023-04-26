require 'rails_helper'

describe QuestionnaireTypeNode do
  let(:questionnaire_type_node) { FactoryBot.build(:questionnaire_type_node) }
  let(:questionnaire) { FactoryBot.build(:questionnaire) }
  let(:questionnaire2) { FactoryBot.build(:questionnaire) }
  let(:questionnaire3) { FactoryBot.build(:questionnaire) }


  describe '#get' do
    it 'gets nodes associated with the parent' do
      tree_folder = double('TreeFolder', id: 1)
      allow(TreeFolder).to receive(:find_by).with(name: 'Questionnaires').and_return(tree_folder)
      allow(TreeFolder).to receive(:where).with(parent_id: 1).and_return([double('FolderNode', id: 1)])
      allow(FolderNode).to receive(:find_by).with(node_object_id: 1).and_return(double('QuestionnaireNode'))
      expect(QuestionnaireTypeNode.get.length).to eq(1)
    end
  end
  describe '#get_partial_name' do
    it 'returns questionnaire_type_actions' do
      expect(questionnaire_type_node.partial_name).to eq('questionnaire_type_actions')
    end
  end
  describe '#get_name' do
    it 'returns the name of the associated tree folder' do
      tree_folder = double('TreeFolder', id: 1)
      allow(TreeFolder).to receive(:find).with(1).and_return(tree_folder)
      allow(tree_folder).to receive(:name).and_return('No folder')
      expect(questionnaire_type_node.name).to eq('No folder')
    end
  end
  describe '#get_children' do
    it 'returns the children objects' do
      arr = [questionnaire, questionnaire2, questionnaire3]
      allow(QuestionnaireNode).to receive(:get).and_return(arr)
      expect(questionnaire_type_node.children.first).to be(questionnaire)
    end
  end
end