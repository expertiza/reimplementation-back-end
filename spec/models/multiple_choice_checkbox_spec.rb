require 'rails_helper'

RSpec.describe MultipleChoiceCheckbox, type: :model do
  it 'defines the edit method' do
    expect(MultipleChoiceCheckbox.method_defined?(:edit)).to be true
  end

  it 'defines the complete method' do
    expect(MultipleChoiceCheckbox.method_defined?(:complete)).to be true
  end

  it 'defines the view_completed_question method' do
    expect(MultipleChoiceCheckbox.method_defined?(:view_completed_question)).to be true
  end

  it 'defines the is_valid method' do
    expect(MultipleChoiceCheckbox.method_defined?(:is_valid)).to be true
  end
end