# Inherits from ApplicationRecord, representing advices associated with questions in a questionnaire
class QuestionAdvice < ApplicationRecord
  # Establishes a belongs_to association with the Question model
  belongs_to :question

  # Class method to define the fields to be exported for QuestionAdvice records
  def self.export_fields(_options)
    # Retrieves and maps the column names of the QuestionAdvice table
    QuestionAdvice.columns.map(&:name)
  end

  # Class method to export QuestionAdvice records related to a specific questionnaire to CSV
  def self.export(csv, parent_id, _options)
    # Finds the Questionnaire by the given parent_id
    questionnaire = Questionnaire.find(parent_id)
    # Iterates over each question in the questionnaire
    questionnaire.questions.each do |question|
      # Fetches and iterates over each piece of advice for the current question
      QuestionAdvice.where(question_id: question.id).each do |advice|
        # Adds the advice attributes' values to the CSV
        csv << advice.attributes.values
      end
    end
  end

  # Class method to convert advices related to a specific question into JSON format
  def self.to_json_by_question_id(question_id)
    # Retrieves QuestionAdvice records for a specific question, ordered by id
    question_advices = QuestionAdvice.where(question_id: question_id).order(:id)
    # Maps each advice to a hash with its score and advice content
    question_advices.map do |advice|
      { score: advice.score, advice: advice.advice }
    end
  end
end