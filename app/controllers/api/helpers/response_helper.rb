module ResponseHelper
    # E2218: this module contains methods that are used in response_controller class
  
    # E-1973 - helper method to check if the current user is the reviewer
    # if the reviewer is an assignment team, we have to check if the current user is on the team
    def current_user_is_reviewer?(map, _reviewer_id)
      map.reviewer.current_user_is_reviewer? current_user.try(:id)
    end
  
    # sorts the questions passed by sequence number in ascending order
    def sort_questions(questions)
      questions.sort_by(&:seq)
    end
  
    # Assigns total contribution for cake question across all reviewers to a hash map
    # Key : question_id, Value : total score for cake question
    def store_total_cake_score
      reviewee = ResponseMap.select(:reviewee_id, :type).where(id: @response.map_id.to_s).first
      @total_score = Cake.get_total_score_for_questions(reviewee.type,
                                                        @review_questions,
                                                        @participant.id,
                                                        @assignment.id,
                                                        reviewee.reviewee_id)
    end
  
    # new_response if a flag parameter indicating that if user is requesting a new rubric to fill
    # if true: we figure out which questionnaire to use based on current time and records in assignment_questionnaires table
    # e.g. student click "Begin" or "Update" to start filling out a rubric for others' work
    # if false: we figure out which questionnaire to display base on @response object
    # e.g. student click "Edit" or "View"
    def set_content(new_response = false)
      @title = @map.get_title
      if @map.survey?
        @survey_parent = @map.survey_parent
      else
        @assignment = @map.assignment
      end
      @participant = @map.reviewer
      @contributor = @map.contributor
      new_response ? questionnaire_from_response_map : questionnaire_from_response
      set_dropdown_or_scale
      @review_questions = sort_questions(@questionnaire.questions)
      @min = @questionnaire.min_question_score
      @max = @questionnaire.max_question_score
      # The new response is created here so that the controller has access to it in the new method
      # This response object is populated later in the new method
      if new_response
        @response = Response.create(map_id: @map.id, additional_comment: '', round: @current_round, is_submitted: 0)
      end
    end

    # def sortResponses(review_scores)
    #   review_scores.sort do |m1, m2|
    #     if m1.version_num.to_i && m2.version_num.to_i
    #       m2.version_num.to_i <=> m1.version_num.to_i
    #     else
    #       m1.version_num ? -1 : 1
    #     end
    #   end
    #   review_scores
    # end

     # This method is used to send email from a Reviewer to an Author.
    # Email body and subject are inputted from Reviewer and passed to send_mail_to_author_reviewers method in MailerHelper.
    def send_emails
      subject = params['send_email']['subject']
      body = params['send_email']['email_body']
      response = params['response']
      email = params['email']
  
      respond_to do |format|
        if subject.blank? || body.blank?
          flash[:error] = 'Please fill in the subject and the email content.'
          format.html { redirect_to controller: 'response', action: 'author', response: response, email: email }
          format.json { head :no_content }
        else
          # make a call to method invoking the email process
          MailerHelper.send_mail_to_author_reviewers(subject, body, email)
          flash[:success] = 'Email sent to the author.'
          format.html { redirect_to controller: 'student_task', action: 'list' }
          format.json { head :no_content }
        end
      end
    end
    def redirect
      error_id = params[:error_msg]
      message_id = params[:msg]
      flash[:error] = error_id unless error_id&.empty?
      flash[:note] = message_id unless message_id&.empty?
      @map = Response.find_by(map_id: params[:id])
      case params[:return]
      when 'feedback'
        redirect_to controller: 'grades', action: 'view_my_scores', id: @map.reviewer.id
      when 'teammate'
        redirect_to view_student_teams_path student_id: @map.reviewer.id
      when 'instructor'
        redirect_to controller: 'grades', action: 'view', id: @map.response_map.assignment.id
      when 'assignment_edit'
        redirect_to controller: 'assignments', action: 'edit', id: @map.response_map.assignment.id
      when 'selfreview'
        redirect_to controller: 'submitted_content', action: 'edit', id: @map.response_map.reviewer_id
      when 'survey'
        redirect_to controller: 'survey_deployment', action: 'pending_surveys'
      when 'bookmark'
        bookmark = Bookmark.find(@map.response_map.reviewee_id)
        redirect_to controller: 'bookmarks', action: 'list', id: bookmark.topic_id
      when 'ta_review' # Page should be directed to list_submissions if TA/instructor performs the review
        redirect_to controller: 'assignments', action: 'list_submissions', id: @map.response_map.assignment.id
      else
        # if reviewer is team, then we have to get the id of the participant from the team
        # the id in reviewer_id is of an AssignmentTeam
        reviewer_id = @map.response_map.reviewer.get_logged_in_reviewer_id(current_user.try(:id))
        redirect_to controller: 'student_review', action: 'list', id: reviewer_id
      end
    end
  end