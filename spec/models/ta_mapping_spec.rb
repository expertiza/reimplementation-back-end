# frozen_string_literal: true

require 'rails_helper'
require 'json_web_token'

RSpec.describe TaMapping, type: :model do

  let(:ta) {create(:user, :ta)}
  let(:course) {create(:course)}

  let(:ta_token) { JsonWebToken.encode({id: ta.id}) }

  describe 'Teaching Assistant access' do
    before do
      TaMapping.create!(course_id: course.id, user_id: ta.id)
    end

    it 'creates the TA mapping' do
      expect(TaMapping.exists?(course_id: course.id, user_id: ta.id)).to be true
    end
  end
end
