# app/models/sign_up_sheet.rb
class SignUpSheet
    def self.signup_team(assignment_id, user_id, topic_id)
      # TEMP MOCK: You can log or skip logic for now
      Rails.logger.info "⚠️ Called SignUpSheet.signup_team(#{assignment_id}, #{user_id}, #{topic_id})"
    end
  end
  