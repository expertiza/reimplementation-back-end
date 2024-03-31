class Questionnaire < ApplicationRecord
  # belongs_to :assignment, foreign_key: 'assignment_id', inverse_of: false
  belongs_to :instructor # creator of the questionnaire
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

  ## Computes the max possible score of all the questions
  def max_possible_score
    ## Just return 0 if there are no questions; don't throw an error.
    return 0 if questions.empty?

    ## Sums up the weight of all the questions. This is not necessarily 1.
    sum_of_weights = questions.sum{ | question| quesitons.weight}
    max_possible_score = sum_of_weights * max_possible_score
  end

  # clones the contents of a questionnaire, including the questions and associated advice
  # Removed unnecessary assignment of questions variable since we can directly access questions associated with the original questionnaire.
  # Used string interpolation for setting the name of the copied questionnaire.
  # Wrapped the copying process in a transaction to ensure data consistency.
  # Simplified the duplication process by directly assigning the questionnaire to the new questions being created.
  # Transactions are protective blocks where SQL statements are only permanent if they can all succeed as one atomic action.  To maintain data consistency
  def self.copy_questionnaire_details(params)
    orig_questionnaire = find(params[:id])
    questionnaire = orig_questionnaire.dup
    questionnaire.name = "Copy of #{orig_questionnaire.name}"
    questionnaire.created_at = Time.zone.now
    questionnaire.updated_at = Time.zone.now

    ActiveRecord::Base.transaction do
      questionnaire.save!
      orig_questionnaire.questions.each do |question|
        new_question = question.dup
        new_question.questionnaire_id = questionnaire.id
        new_question.save!
      end
    end

    questionnaire
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
