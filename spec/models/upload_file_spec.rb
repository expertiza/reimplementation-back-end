require 'rails_helper'

RSpec.describe UploadFile, type: :model do
  describe '#edit' do
    it 'renders the edit partial' do
      # verify that the method is defined.
      expect(UploadFile.new).to respond_to(:edit)
    end
  end

  describe '#view_question_text' do
    it 'renders the view_question_text partial' do
      #verify that the method is defined.
      expect(UploadFile.new).to respond_to(:view_question_text)
    end
  end

  describe '#complete' do
    it 'implements the logic for completing a question' do
      # Write your test for the complete method logic here.
    end
  end

  describe '#view_completed_question' do
    it 'implements the logic for viewing a completed question by a student' do
      # Write your test for the view_completed_question method logic here.
    end
  end
end
