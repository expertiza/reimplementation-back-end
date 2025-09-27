# frozen_string_literal: true

class SignedUpTeam < ApplicationRecord
  belongs_to :sign_up_topic
  belongs_to :team
end
