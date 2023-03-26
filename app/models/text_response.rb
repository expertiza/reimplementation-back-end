class TextResponse < Question
  # Text response has methods describing views for viewing or editing a questionnaire
  validates :size, presence: true

end
