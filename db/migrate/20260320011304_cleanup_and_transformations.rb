class CleanupAndTransformations < ActiveRecord::Migration[8.0]
  def up
    # -------------------------
    # USERS TABLE
    # -------------------------
    rename_column :users, :name, :username if column_exists?(:users, :name)
    rename_column :users, :full_name, :name if column_exists?(:users, :full_name)
    if column_exists?(:users, "timeZonePref")
      rename_column :users, "timeZonePref", :time_zone_pref
    else
      # This will print in your terminal during migrate so you know what happened
      say "WARNING: timeZonePref not found in users table!", true 
    end
    remove_column :users, :mru_directory_path if column_exists?(:users, :mru_directory_path)
    remove_column :users, :email_on_review if column_exists?(:users, :email_on_review)
    remove_column :users, :email_on_review_of_review if column_exists?(:users, :email_on_review_of_review)
    remove_column :users, :master_permission_granted if column_exists?(:users, :master_permission_granted)
    remove_column :users, :digital_certificate if column_exists?(:users, :digital_certificate)
    remove_column :users, :persistence_token if column_exists?(:users, :persistence_token)
    add_column :users, :public_key, :text unless column_exists?(:users, :public_key)
    add_column :users, :private_by_default, :boolean unless column_exists?(:users, :private_by_default)
    add_column :users, :password_salt, :text unless column_exists?(:users, :password_salt)
    # -------------------------
    # ASSIGNMENTS TABLE
    # -------------------------
    rename_column :assignments, :spec_location, :URL if column_exists?(:assignments, :spec_location)
    rename_column :assignments, :is_intelligent, :topics_assigned_by_bidding if column_exists?(:assignments, :is_intelligent)
    rename_column :assignments, :availability_flag, :available_to_students if column_exists?(:assignments, :availability_flag)
    rename_column :assignments, :use_bookmark, :can_bookmark_topics if column_exists?(:assignments, :use_bookmark)

    remove_column :assignments, :max_bids if column_exists?(:assignments, :max_bids)
    remove_column :assignments, :reputation_algorithm if column_exists?(:assignments, :reputation_algorithm)
    remove_column :assignments, :simicheck if column_exists?(:assignments, :simicheck)
    remove_column :assignments, :simicheck_threshold if column_exists?(:assignments, :simicheck_threshold)
    remove_column :assignments, :has_badge if column_exists?(:assignments, :has_badge)
    remove_column :assignments, :is_conference_assignment if column_exists?(:assignments, :is_conference_assignment)
    add_column :assignments, :vary_by_topic?, :boolean unless column_exists?(:assignments, :vary_by_topic?)
    add_column :assignments, :vary_by_round?, :boolean unless column_exists?(:assignments, :vary_by_round?)
    add_column :assignments, :team_reviewing_enabled, :boolean unless column_exists?(:assignments, :team_reviewing_enabled)
    add_column :assignments, :bidding_for_reviews_enabled, :boolean unless column_exists?(:assignments, :bidding_for_reviews_enabled)
    add_column :assignments, :auto_assign_mentor, :boolean unless column_exists?(:assignments, :auto_assign_mentor)
    add_column :assignments, :team_members_have_duty, :boolean unless column_exists?(:assignments, :team_members_have_duty)
    add_column :assignments, :vary_by_duty?, :boolean unless column_exists?(:assignments, :vary_by_duty?)    
    
    # -------------------------
    # PARTICIPANTS TABLE
    # -------------------------
    change_column :participants, :user_id, :bigint if column_exists?(:participants, :user_id)

    remove_column :participants, :submitted_at if column_exists?(:participants, :submitted_at)
    remove_column :participants, :penalty_accumulated if column_exists?(:participants, :penalty_accumulated)
    remove_column :participants, :time_stamp if column_exists?(:participants, :time_stamp)
    remove_column :participants, :digital_signature if column_exists?(:participants, :digital_signature)
    remove_column :participants, :duty if column_exists?(:participants, :duty)
    remove_column :participants, :duty_id if column_exists?(:participants, :duty_id)

    rename_column :participants, :permission_granted, :OK_to_show if column_exists?(:participants, :permission_granted)

    add_column :participants, :can_mentor, :boolean unless column_exists?(:participants, :can_mentor)

    # -------------------------
    # SUBMISSION RECORDS
    # -------------------------
    rename_column :submission_records, :type, :record_type if column_exists?(:submission_records, :type)
    rename_column :submission_records, :user, :submitted_by if column_exists?(:submission_records, :user)

    remove_column :submission_records, :assignment_id if column_exists?(:submission_records, :assignment_id)

    # -------------------------
    # SUGGESTIONS
    # -------------------------
    rename_column :suggestions, :unityID, :username if column_exists?(:suggestions, :unityID)

    # -------------------------
    # REVIEW BIDS
    # -------------------------
    rename_column :review_bids, :signuptopic_id, :project_topic_id if column_exists?(:review_bids, :signuptopic_id)

    # -------------------------
    # BOOKMARK RATINGS
    # -------------------------
    rename_column :bookmark_ratings, :bookmark_id, :artifact_id if column_exists?(:bookmark_ratings, :bookmark_id)
    rename_column :bookmark_ratings, :user_id, :rater_id if column_exists?(:bookmark_ratings, :user_id)
    rename_column :bookmark_ratings, :rating, :ratings if column_exists?(:bookmark_ratings, :rating)

    # -------------------------
    # COURSES
    # -------------------------
    rename_column :courses, :private, :is_private if column_exists?(:courses, :private)
    rename_column :courses, :institutions_id, :institution_id if column_exists?(:courses, :institutions_id)
    add_column :courses, :language, :text unless column_exists?(:courses, :language)

    # -------------------------
    # DUE DATES
    # -------------------------
    rename_column :due_dates, :parent_id, :assignment_id if column_exists?(:due_dates, :parent_id)

    # -------------------------
    # RESPONSES
    # -------------------------
    rename_column :responses, :map_id, :response_map_id if column_exists?(:responses, :map_id)

    # -------------------------
    # QUIZ_QUESTION_CHOICES
    # -------------------------
    rename_column :quiz_question_choices, :iscorrect, :is_correct if column_exists?(:quiz_question_choices, :iscorrect)
    
    # -------------------------
    # ASSIGNMENT_QUESTIONNAIRES
    # -------------------------
    rename_column :assignment_questionnaires, :notification_limit, :notification_threshold if column_exists?(:assignment_questionnaires, :notification_limit)
    add_column :assignment_questionnaires, :dropdown, :boolean unless column_exists?(:survey_deployments, :dropdown)
    add_column :assignment_questionnaires, :topic_id, :bigint unless column_exists?(:survey_deployments, :topic_id)
    add_column :assignment_questionnaires, :duty_id, :bigint unless column_exists?(:survey_deployments, :duty_id)
    
    # -------------------------
    # SURVEY_DEPLOYMENTS
    # -------------------------
    add_column :survey_deployments, :type, :text unless column_exists?(:survey_deployments, :type)
    
    # -------------------------
    # ROLES
    # -------------------------
    add_column :roles, :description, :text unless column_exists?(:roles, :description)
    
    # -------------------------
    # RESPONSES
    # -------------------------
    add_column :responses, :visibility, :text unless column_exists?(:responses, :visibility)
    
    # -------------------------
    # RESPONSES
    # -------------------------
    add_column :response_maps, :for_calibration, :boolean unless column_exists?(:response_maps, :for_calibration)
    
    # -------------------------
    # ITEMS
    # -------------------------
    add_column :items, :type, :text unless column_exists?(:items, :type)

    # -------------------------
    # QUESTIONNAIRES
    # -------------------------
    add_column :questionnaires, :type, :text unless column_exists?(:questionnaires, :type)
    
    # -------------------------
    # QUESTION_TYPES
    # -------------------------
    add_column :question_types, :type, :text unless column_exists?(:question_types, :type)

    # -------------------------
    # JOIN_TEAM_REQUESTS
    # -------------------------
    add_column :join_team_requests, :status, :text unless column_exists?(:join_team_requests, :status)

    # -------------------------
    # DUTIES
    # -------------------------
    add_column :duties, :assignment_id, :bigint unless column_exists?(:duties, :assignment_id)
    

    # -------------------------
    # TABLE RENAMES
    # -------------------------
    if table_exists?(:teams_users) && !table_exists?(:teams_participants)
      rename_table :teams_users, :teams_participants
    end
  if table_exists?(:question_advices) && !table_exists?(:question_advice)
    rename_table :question_advices, :question_advice
  end

  if table_exists?(:bids) && !table_exists?(:topic_bids)
    rename_table :bids, :topic_bids
  end

    # -------------------------
    # DATA MIGRATION (IMPORTANT)
    # -------------------------
    if column_exists?(:signed_up_teams, :advertise_for_partner) &&
      column_exists?(:teams, :advertise_for_partner)

      execute <<-SQL
        UPDATE signed_up_teams sut
        JOIN teams t ON sut.team_id = t.id
        SET
          sut.comments_for_advertisement = t.comments_for_advertisement,
          sut.advertise_for_partner = t.advertise_for_partner
      SQL

    end

    # -------------------------
    # CLEANUP TABLES
    # -------------------------
    drop_table :awarded_badges, if_exists: true
    drop_table :badges, if_exists: true
    drop_table :calculated_penalties, if_exists: true
    drop_table :delayed_jobs, if_exists: true
    drop_table :locks, if_exists: true
    drop_table :menu_items, if_exists: true
    drop_table :plagiarism_checker_assignment_submissions, if_exists: true
    drop_table :plagiarism_checker_comparisons, if_exists: true
    drop_table :sections, if_exists: true
    drop_table :system_settings, if_exists: true
    drop_table :content_pages, if_exists: true
    drop_table :controller_actions, if_exists: true
    drop_table :markup_styles, if_exists: true
    drop_table :notifications, if_exists: true
    drop_table :ar_internal_metadata, if_exists: true
    drop_table :site_controllers, if_exists: true

    # -------------------------
    # NEW TABLE
    # -------------------------
    create_table :questionnaire_types do |t|
      t.string :display_type, null: false
    end unless table_exists?(:questionnaire_types)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end