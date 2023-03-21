class QuestionnairesController < ApplicationController
  include AuthorizationHelper

  # Controller for Questionnaire objects
  # A Questionnaire can be of several types (QuestionnaireType)
  # Each Questionnaire contains zero or more questions (Question)
  # Generally a questionnaire is associated with an assignment (Assignment)

  
  skip_before_action :verify_authenticity_token

  # Check role access for edit questionnaire
  def action_allowed?
    case params[:action]
    when 'edit'
      @questionnaire = Questionnaire.find(params[:id])
      current_user_has_admin_privileges? ||
        (current_user_is_a?('Instructor') && current_user_id?(@questionnaire.try(:instructor_id))) ||
        (current_user_is_a?('Teaching Assistant') && session[:user].instructor_id == @questionnaire.try(:instructor_id))
    else
      current_user_has_student_privileges?
    end
  end

  #List all the questionnaires
  # GET on /questionnaires
  def index
    @questionnaires = Questionnaire.order(:id)
    render json: @questionnaires
  end
  
  #Show a given questionnaire
  # GET on /questionnaires/:id
  def show
    begin
      @questionnaire = Questionnaire.find(params[:id])
      render json: @questionnaire
    rescue
      msg = "No such Questionnaire exists."
      render json: msg, status: :not_found
    end
  end
  
  #Create a given questionnaire
  # POST on /questionnaires
  def create
    if params[:questionnaire][:name].blank?
      redirect_to controller: 'questionnaires', action: 'new', model: params[:questionnaire][:type], private: params[:questionnaire][:private]
    else
      questionnaire_private = params[:questionnaire][:private] == 'true'
      display_type = params[:questionnaire][:type].split('Questionnaire')[0]
      begin
        @questionnaire = Object.const_get(params[:questionnaire][:type]).new if Questionnaire::QUESTIONNAIRE_TYPES.include? params[:questionnaire][:type]
      rescue StandardError
        msg = $ERROR_INFO
        render json: msg
      end
      begin
        @questionnaire.private = questionnaire_private
        @questionnaire.name = params[:questionnaire][:name]
        @questionnaire.instructor_id = 6 # session[:user].id
        @questionnaire.min_question_score = params[:questionnaire][:min_question_score]
        @questionnaire.max_question_score = params[:questionnaire][:max_question_score]
        @questionnaire.type = params[:questionnaire][:type]
        if %w[AuthorFeedback CourseSurvey TeammateReview GlobalSurvey AssignmentSurvey BookmarkRating].include?(display_type)
          display_type = (display_type.split(/(?=[A-Z])/)).join('%')
        end
        @questionnaire.display_type = display_type
        @questionnaire.instruction_loc = Questionnaire::DEFAULT_QUESTIONNAIRE_URL
        @questionnaire.save
        # Create node
        tree_folder = TreeFolder.where(['name like ?', @questionnaire.display_type]).first
        parent = FolderNode.find_by(node_object_id: tree_folder.id)
        QuestionnaireNode.create(parent_id: parent.id, node_object_id: @questionnaire.id, type: 'QuestionnaireNode')
        render json: @questionnaire, status: :created
      rescue StandardError
        msg = $ERROR_INFO
        render json: msg
      end
     
    end
  end

  # Remove a given questionnaire
  # DELETE on /questionnaires/:id
  def destroy
    begin
      @questionnaire = Questionnaire.find(params[:id])
    rescue
      render json: $ERROR_INFO
    end
    if @questionnaire
      begin
        name = @questionnaire.name
        questions = @questionnaire.questions
        questions.each do |question|
          advices = question.question_advices
          advices.each(&:delete)
          question.delete
        end
        questionnaire_node = @questionnaire.questionnaire_node
        questionnaire_node.delete if !questionnaire_node.nil?
        @questionnaire.delete
        render json: "The questionnaire \"#{name}\" has been successfully deleted."
      rescue StandardError => e
        render json: e.message
      end
    end
  end

  #Update a given questionnaire
  # PUT on /questionnaires/:id
  def update
    # If 'Add' or 'Edit/View advice' is clicked, redirect appropriately
      begin
        # Save questionnaire information
        @questionnaire = Questionnaire.find(params[:id])
        @questionnaire.update_attributes(questionnaire_params)
        # Save all questions
        unless params[:question].nil?
          params[:question].each_pair do |k, v|
            @question = Question.find(k)
            # example of 'v' value
            # {"seq"=>"1.0", "txt"=>"WOW", "weight"=>"1", "size"=>"50,3", "max_label"=>"Strong agree", "min_label"=>"Not agree"}
            v.each_pair do |key, value|
              @question.send(key + '=', value) unless @question.send(key) == value
            end
            @question.save
          end
        end
        render json: 'The questionnaire has been successfully updated!'
      rescue StandardError
        render json: $ERROR_INFO

      end
  end

  # Create a clone of the given questionnaire, copying all associated
  # questions. The name and creator are updated.
  # POST on /questionnaires/copy/:id
  def copy
    # <Auth code add later>
    # instructor_id = session[:user].instructor_id
    instructor_id = 6
    @questionnaire = Questionnaire.copy_questionnaire_details(params, instructor_id)
    p_folder = TreeFolder.find_by(name: @questionnaire.display_type)
    parent = FolderNode.find_by(node_object_id: p_folder.id)
    QuestionnaireNode.find_or_create_by(parent_id: parent.id, node_object_id: @questionnaire.id)
    render json: "Copy of questionnaire #{@questionnaire.name} has been created successfully."
  rescue StandardError
    render json: 'The questionnaire was not able to be copied. Please check the original course for missing information.' + $ERROR_INFO.to_s
  end

  # Toggle the access permission for this assignment from public to private, or vice versa
  # GET on /questionnaires/toggle_access/:id
  def toggle_access
    @questionnaire = Questionnaire.find(params[:id])
    @questionnaire.private = !@questionnaire.private
    @questionnaire.save
    @access = @questionnaire.private == true ? 'private' : 'public'
    render json: "The questionnaire \"#{@questionnaire.name}\" has been successfully made #{@access}. "
  end

  private
  def questionnaire_params
    params.permit(:name, :instructor_id, :private, :min_question_score,
                                          :max_question_score, :type, :display_type, :instruction_loc)
  end
end
