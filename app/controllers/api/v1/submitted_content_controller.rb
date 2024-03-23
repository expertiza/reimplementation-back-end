class Api::V1::SubmittedContentController < ApplicationController
    require 'mimemagic'
    require 'mimemagic/overlay'
  
    include AuthorizationHelper
  
    def action_allowed?
      case params[:action]
      when 'edit'
        current_user_has_student_privileges? &&
          are_needed_authorizations_present?(params[:id], 'reader', 'reviewer')
      when 'submit_file', 'submit_hyperlink'
        current_user_has_student_privileges? &&
          one_team_can_submit_work?
      else
        current_user_has_student_privileges?
      end
    end

    def controller_locale
      locale_for_student
    end
end  
