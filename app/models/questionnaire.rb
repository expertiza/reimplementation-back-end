class Questionnaire < ApplicationRecord
  # belongs_to :assignment, foreign_key: 'assignment_id', inverse_of: false
  belongs_to :instructor # creator of the questionnaire
  before_destroy :check_for_question_associations # need to check before association or they will be destroyed and this will never evaluate
  has_many :questions, dependent: :destroy # the collection of questions associated with this Questionnaire
  has_many :assignment_questionnaires, dependent: :destroy
  has_many :assignments, through: :assignment_questionnaires
  has_one :questionnaire_node, foreign_key: 'node_object_id', dependent: :destroy, inverse_of: :questionnaire

  validates :name, presence: true
  validate :name_is_unique
  validates :max_question_score, numericality: { only_integer: true, greater_than: 0 }, presence: true
  validates :min_question_score, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, presence: true
  validate :min_less_than_max

  def delete
    # Check to see if we go further? we cannot proceed if there are any assignments
    assignment = assignments.first
    if assignment
      raise "The assignment #{assignment.name} uses this questionnaire. Do you want to <A href='../assignment/delete/#{assignment.id}'>delete</A> the assignment?"
    end

    questions.each(&:delete)

    node = QuestionnaireNode.find_by(node_object_id: id)
    node&.destroy

    destroy
  end

  def min_less_than_max
    # do we have values if not then do not attempt to validate this
    return unless min_question_score && max_question_score

    errors.add(:min_question_score, 'must be less than max question score') if min_question_score >= max_question_score
  end

  def name_is_unique
    # return if we do not have all the values to check
    return unless id && name && instructor_id

    # check for existing named questionnaire for this instructor that is not this questionnaire
    existing = Questionnaire.where('name = ? and instructor_id = ? and id <> ?', name, instructor_id, id)
    errors.add(:name, 'must be unique') if existing.present?
  end

  # clones the contents of a questionnaire, including the questions and associated advice
  def self.copy_questionnaire_details(params)
    orig_questionnaire = Questionnaire.find(params[:id])
    questions = Question.where(questionnaire_id: params[:id])
    questionnaire = orig_questionnaire.dup
    questionnaire.name = "Copy of #{orig_questionnaire.name}"
    questionnaire.created_at = Time.zone.now
    questionnaire.updated_at = Time.zone.now
    questionnaire.save!
    questions.each do |question|
      new_question = question.dup
      new_question.questionnaire_id = questionnaire.id
      new_question.save!
    end
    questionnaire
  end

  # Check_for_question_associations checks if questionnaire has associated questions or not
  def check_for_question_associations
    if questions.any?
      raise ActiveRecord::DeleteRestrictionError.new("Cannot delete record because dependent questions exist")
    end
  end

  def as_json(options = {})
    super(options.merge({
                            only: %i[id name private min_question_score max_question_score created_at updated_at questionnaire_type instructor_id],
                            include: {
                              instructor: { only: %i[name email fullname password role]
                            }
                            }
                          })).tap do |hash|
        hash['instructor'] ||= { id: nil, name: nil }
      end
  end

  def get_weighted_score(assignment, scores)
    compute_weighted_score(questionnaire_symbol(assignment), assignment, scores)
  end

  def compute_weighted_score(symbol, assignment, scores)
    aq = assignment_questionnaires.find_by(assignment_id: assignment.id)
    scores[symbol][:scores][:avg].nil? ? 0 : scores[symbol][:scores][:avg] * aq.questionnaire_weight / 100.0
  end

  # Does this questionnaire contain true/false questions?
  def true_false_questions?
    questions.each { |question| return true if question.question_type == 'Checkbox' }
    false
  end

  private
  def questionnaire_symbol(assignment)
    # create symbol for "varying rubrics" feature
    # Credit ChatGPT to help me get from the inline below to the used inline, the yield self allowed me the work I wanted to do
    # AssignmentQuestionnaire.find_by(assignment_id: assignment.id, questionnaire_id: id)&.used_in_round ? "#{symbol}#{round}".to_sym : symbol
    AssignmentQuestionnaire.find_by(assignment_id: assignment.id, questionnaire_id: id)&.used_in_round&.yield_self { |round| "#{symbol}#{round}".to_sym } || symbol
  end
end
