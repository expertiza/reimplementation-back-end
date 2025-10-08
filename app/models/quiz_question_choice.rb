# frozen_string_literal: true

class QuizQuestionChoice < ApplicationRecord
    belongs_to :item, dependent: :destroy
  end