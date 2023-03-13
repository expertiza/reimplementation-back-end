class Api::V1::QuestionnairesController < ApplicationController

  # GET /api/v1/questionnaires/view
  def view
    @questionnaires = Questionnaire.order(:id)
    render json: @questionnaires
  end

  # GET /api/v1/questionnaire/:id
  def show
    @questionnaire = Questionnaire.find(params[:id])
    render json: @questionnaire
  end

  # GET /api/v1/questionnaire/copy/:id
  def copy
    @questionnaire = Questionnaire.find(params[:id])
    instructor_id = @questionnaire.instructor_id
    @questionnaire = Questionnaire.copy_questionnaire_details(params, instructor_id)
    p_folder = TreeFolder.find_by(name: @questionnaire.display_type)
    parent = FolderNode.find_by(node_object_id: p_folder.id)
    QuestionnaireNode.find_or_create_by(parent_id: parent.id, node_object_id: @questionnaire.id)
    undo_link("Copy of questionnaire #{@questionnaire.name} has been created successfully.")
    render json: @questionnaire
  rescue StandardError
    error_msg = 'The questionnaire was not able to be copied. Please check the original course for missing information.' + $ERROR_INFO.to_s
    render json: error_msg
    
  end

  private
  def questionnaire_params
    params.permit(:name, :instructor_id, :private, :min_question_score,
                                          :max_question_score, :type, :display_type, :instruction_loc)
  end

  def question_params
    params.require(:question).permit(:txt, :weight, :questionnaire_id, :seq, :type, :size,
                                     :alternatives, :break_before, :max_label, :min_label)
  end

end
