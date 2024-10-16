class Question < ApplicationRecord
  before_create :set_seq
  belongs_to :questionnaire # each question belongs to a specific questionnaire
  has_many :answers, dependent: :destroy
  has_many :question_advices, dependent: :destroy
  
  validates :seq, presence: true, numericality: true # sequence must be numeric
  validates :txt, length: { minimum: 0, allow_nil: false, message: "can't be nil" } # user must define text content for a question
  validates :question_type, presence: true # user must define type for a question
  validates :break_before, presence: true

  # Class variables - used questionnaires_controller.rb to set the parameters for a question.
  MAX_LABEL = 'Strongly agree'.freeze
  MIN_LABEL = 'Strongly disagree'.freeze
  SIZES = { 'Criterion' => '50, 3', 'Cake' => '50, 3', 'TextArea' => '60, 5', 'TextField' => '30' }.freeze
  ALTERNATIVES = { 'Dropdown' => '0|1|2|3|4|5' }.freeze
  attr_accessor :checked

  def scorable?
    false
  end
  
  def delete
    QuestionAdvice.where(question_id: id).find_each(&:destroy)
    destroy
  end

  def set_seq
    self.seq = questionnaire.questions.size + 1
  end

  def self.compute_question_score
    0
  end

  # this method return questions (question_ids) in one assignment whose comments field are meaningful (ScoredQuestion and TextArea)
  def self.fetch_question_ids_with_comments(assignment_id)
    question_ids = []
    questionnaires = Assignment.find(assignment_id).questionnaires.select { |questionnaire| questionnaire.type == 'ReviewQuestionnaire' }
    questionnaires.each do |questionnaire|
      questions = questionnaire.questions.select { |question| question.is_a?(ScoredQuestion) || question.instance_of?(TextArea) }
      questions.each { |question| question_ids << question.id }
    end
    question_ids
  end

  def self.import(row_hash, _row_hash, _session, q_id)
    # Ensure the row has the required fields
    required_fields = [:txt, :type, :seq, :size, :breakbefore]
    missing_fields = required_fields - row_hash.keys

    raise ArgumentError, "Missing fields: #{missing_fields.join(', ')}" unless missing_fields.empty?

    questionnaire = Questionnaire.find_by(id: q_id)
    raise ArgumentError, 'Questionnaire Not Found' if questionnaire.nil?

    # Find an existing question with matching sequence
    existing_question = questionnaire.questions.find_by(seq: row_hash[:seq].to_f)

    attributes = {
      txt: row_hash[:txt],
      type: row_hash[:type],
      seq: row_hash[:seq].to_f,
      size: row_hash[:size],
      break_before: row_hash[:breakbefore]
    }

    if existing_question
      # Update the existing question
      existing_question.update!(attributes)
    else
      # Create a new question
      questionnaire.questions.create!(attributes)
    end
  end

  def self.export_fields(_options)
    fields = ['Seq', 'Question', 'Type', 'Weight', 'text area size', 'max_label', 'min_label']
    fields
  end

  def self.export(csv, parent_id, _options)
    questionnaire = Questionnaire.find(parent_id)
    questionnaire.questions.each do |question|
      csv << [question.seq, question.txt, question.type,
              question.weight, question.size, question.max_label,
              question.min_label]
    end
  end

  def as_json(options = {})
      super(options.merge({
                            only: %i[txt weight seq question_type size alternatives break_before min_label max_label created_at updated_at],
                            include: {
                              questionnaire: { only: %i[name id] }
                            }
                          })).tap do |hash|
      end
  end
end
