# frozen_string_literal: true

class QuizQuestionChoice < ApplicationRecord
    belongs_to :item, dependent: :destroy
    alias_attribute :iscorrect, :is_correct
  end