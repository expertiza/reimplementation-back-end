# frozen_string_literal: true

class BookmarkRating < ApplicationRecord
  belongs_to :bookmark, foreign_key: 'artifact_id'
  belongs_to :user, foreign_key: 'rater_id'
end
