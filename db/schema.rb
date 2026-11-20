# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_11_12_000001) do
  create_table "account_requests", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "role_id"
    t.bigint "institution_id"
    t.string "email"
    t.string "status"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "username"
    t.string "full_name"
    t.text "introduction"
    t.index ["institution_id"], name: "fk_canon_account_requests_institution_id"
    t.index ["role_id"], name: "fk_canon_account_requests_role_id"
  end

  create_table "answer_tags", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "answer_id"
    t.bigint "tag_prompt_deployment_id"
    t.bigint "user_id"
    t.string "value"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.decimal "confidence_level", precision: 10, scale: 5
    t.index ["answer_id"], name: "index_answer_tags_on_answer_id"
    t.index ["tag_prompt_deployment_id"], name: "index_answer_tags_on_tag_prompt_deployment_id"
    t.index ["user_id"], name: "index_answer_tags_on_user_id"
  end

  create_table "answers", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "item_id", default: 0
    t.integer "answer"
    t.text "comments"
    t.integer "response_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["item_id"], name: "fk_score_questions"
    t.index ["response_id"], name: "fk_score_response"
  end

  create_table "assignment_questionnaires", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "assignment_id"
    t.integer "questionnaire_id"
    t.integer "notification_threshold", default: 15
    t.integer "questionnaire_weight"
    t.integer "used_in_round"
    t.boolean "dropdown", default: false, null: false
    t.bigint "topic_id"
    t.bigint "duty_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["assignment_id"], name: "fk_aq_assignments_id"
    t.index ["duty_id"], name: "index_assignment_questionnaires_on_duty_id"
    t.index ["questionnaire_id"], name: "fk_aq_questionnaire_id"
  end

  create_table "assignments", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "name"
    t.string "directory_path"
    t.integer "submitter_count"
    t.bigint "course_id"
    t.bigint "instructor_id"
    t.boolean "private"
    t.integer "num_reviews"
    t.integer "num_review_of_reviews"
    t.integer "num_review_of_reviewers"
    t.boolean "reviews_visible_to_all"
    t.integer "num_reviewers"
    t.text "URL"
    t.boolean "has_badge"
    t.integer "max_team_size"
    t.boolean "staggered_deadline"
    t.boolean "allow_suggestions"
    t.integer "days_between_submissions"
    t.string "review_assignment_strategy"
    t.integer "max_reviews_per_submission"
    t.integer "review_topic_threshold"
    t.boolean "copy_flag"
    t.integer "rounds_of_reviews"
    t.boolean "microtask"
    t.boolean "require_quiz"
    t.integer "num_quiz_questions"
    t.boolean "is_coding_assignment"
    t.boolean "calculate_penalty"
    t.integer "late_policy_id"
    t.boolean "is_penalty_calculated"
    t.boolean "show_teammate_reviews"
    t.boolean "availability_flag"
    t.boolean "use_bookmark"
    t.boolean "can_review_same_topic"
    t.boolean "can_choose_topic_to_review"
    t.boolean "is_calibrated"
    t.boolean "is_selfreview_enabled"
    t.boolean "is_anonymous"
    t.integer "num_reviews_required"
    t.integer "num_metareviews_required"
    t.integer "num_metareviews_allowed"
    t.integer "num_reviews_allowed"
    t.boolean "is_answer_tagging_allowed"
    t.boolean "allow_selecting_additional_reviews_after_1st_round"
    t.integer "sample_assignment_id"
    t.boolean "vary_by_topic?"
    t.boolean "vary_by_round?"
    t.boolean "team_reviewing_enabled"
    t.boolean "bidding_for_reviews_enabled"
    t.boolean "auto_assign_mentor"
    t.boolean "enable_pair_programming", default: false
    t.boolean "team_members_have_duty"
    t.boolean "vary_by_duty?"
    t.integer "instructor_grade_min_score"
    t.integer "instructor_grade_max_score"
    t.boolean "has_teams", default: false
    t.boolean "vary_by_round", default: false
    t.boolean "has_topics", default: false
    t.boolean "vary_by_topic", default: false
    t.boolean "vary_by_role", default: false
    t.boolean "has_mentors", default: false
    t.boolean "team_members_have_duties", default: false
    t.boolean "topics_assigned_by_bidding", default: false
    t.boolean "reviewing_is_done_by_teams", default: false
    t.index ["course_id"], name: "fk_assignments_courses"
    t.index ["instructor_id"], name: "fk_assignments_instructors"
    t.index ["late_policy_id"], name: "fk_late_policy_id"
    t.index ["sample_assignment_id"], name: "fk_rails_b01b82a1a2"
  end

  create_table "assignments_duties", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "assignment_id"
    t.bigint "duty_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["assignment_id"], name: "fk_canon_assignments_duties_assignment_id"
    t.index ["duty_id"], name: "fk_rails_cad6186f05"
  end

  create_table "bookmark_ratings", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "artifact_id"
    t.integer "rater_id"
    t.integer "rating"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "bookmarks", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.text "url"
    t.text "title"
    t.text "description"
    t.integer "user_id"
    t.integer "topic_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["topic_id"], name: "index_bookmarks_on_topic_id"
  end

  create_table "cakes", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "courses", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "name"
    t.bigint "instructor_id"
    t.string "directory_path"
    t.text "info"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "private", default: false
    t.bigint "institution_id"
    t.text "language"
    t.index ["institution_id"], name: "fk_canon_courses_institution_id"
    t.index ["instructor_id"], name: "fk_course_users"
  end

  create_table "deadline_rights", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "name"
  end

  create_table "deadline_types", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "name"
  end

  create_table "due_dates", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "due_at", precision: nil
    t.integer "deadline_type_id"
    t.bigint "assignment_id"
    t.integer "submission_allowed_id"
    t.integer "review_allowed_id"
    t.integer "review_of_review_allowed_id"
    t.integer "round"
    t.boolean "flag", default: false
    t.integer "threshold", default: 1
    t.string "delayed_job_id"
    t.string "deadline_name"
    t.string "description_url"
    t.integer "quiz_allowed_id", default: 1
    t.integer "teammate_review_allowed_id", default: 3
    t.string "type"
    t.string "parent_type"
    t.datetime "created_at", precision: nil
    t.integer "rereview_allowed_id"
    t.integer "resubmission_allowed_id"
    t.datetime "updated_at", precision: nil
    t.index ["assignment_id"], name: "fk_due_dates_assignments"
    t.index ["deadline_type_id"], name: "fk_deadline_type_due_date"
    t.index ["review_allowed_id"], name: "fk_due_date_review_allowed"
    t.index ["review_of_review_allowed_id"], name: "fk_due_date_review_of_review_allowed"
    t.index ["submission_allowed_id"], name: "fk_due_date_submission_allowed"
  end

  create_table "duties", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "name"
    t.integer "max_members_for_duty"
    t.bigint "assignment_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.bigint "instructor_id"
    t.boolean "private", default: false
    t.index ["assignment_id"], name: "index_duties_on_assignment_id"
    t.index ["instructor_id"], name: "fk_canon_duties_instructor_id"
  end

  create_table "institutions", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "invitations", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "assignment_id"
    t.bigint "from_id"
    t.bigint "to_id"
    t.string "reply_status", limit: 1
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["assignment_id"], name: "fk_invitation_assignments"
    t.index ["from_id"], name: "fk_invitationfrom_users"
    t.index ["to_id"], name: "fk_invitationto_users"
  end

  create_table "items", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.text "txt"
    t.integer "weight"
    t.bigint "questionnaire_id"
    t.decimal "seq", precision: 10
    t.text "type"
    t.string "item_type"
    t.string "size"
    t.string "alternatives"
    t.boolean "break_before"
    t.string "max_label"
    t.string "min_label"
    t.string "question_type"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["questionnaire_id"], name: "fk_question_questionnaires"
  end

  create_table "join_team_requests", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "participant_id"
    t.integer "team_id"
    t.text "comments"
    t.text "status"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "reply_status"
  end

  create_table "languages", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "name"
  end

  create_table "late_policies", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.float "penalty_per_unit"
    t.integer "max_penalty", default: 0
    t.string "penalty_unit"
    t.integer "times_used", default: 0
    t.bigint "instructor_id"
    t.string "policy_name"
    t.boolean "private", default: true
    t.index ["instructor_id"], name: "fk_instructor_id"
  end

  create_table "nodes", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "parent_id"
    t.integer "node_object_id"
    t.string "type"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "participants", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.boolean "can_submit", default: true
    t.boolean "can_review", default: true
    t.bigint "user_id"
    t.integer "parent_id"
    t.boolean "permission_granted", default: false
    t.float "grade"
    t.string "type"
    t.string "handle"
    t.boolean "can_take_quiz"
    t.boolean "can_mentor"
    t.bigint "team_id"
    t.string "topic"
    t.string "authorization"
    t.string "current_stage"
    t.datetime "stage_deadline", precision: nil
    t.bigint "join_team_request_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "duty_id"
    t.index ["join_team_request_id"], name: "fk_canon_participants_join_team_request_id"
    t.index ["team_id"], name: "fk_canon_participants_team_id"
    t.index ["user_id"], name: "fk_participant_users"
  end

  create_table "password_resets", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "user_email"
    t.string "token"
    t.datetime "updated_at", precision: nil
  end

  create_table "permissions", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "name"
  end

  create_table "project_topics", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.text "topic_name"
    t.bigint "assignment_id"
    t.integer "max_choosers", default: 0
    t.text "category"
    t.string "topic_identifier", limit: 10
    t.integer "micropayment", default: 0
    t.integer "private_to"
    t.text "description"
    t.string "link"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["assignment_id"], name: "fk_sign_up_categories_sign_up_topics"
    t.index ["assignment_id"], name: "index_project_topics_on_assignment_id"
  end

  create_table "question_advice", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "question_id"
    t.integer "score"
    t.text "advice"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["question_id"], name: "fk_question_question_advices"
  end

  create_table "question_types", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.text "type"
    t.datetime "created_at", precision: nil
    t.string "name"
    t.datetime "updated_at", precision: nil
  end

  create_table "questionnaire_types", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "questionnaires", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "name"
    t.integer "instructor_id"
    t.boolean "private"
    t.integer "min_question_score"
    t.integer "max_question_score"
    t.integer "min_item_score"
    t.integer "max_item_score"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.text "type"
    t.string "display_type"
    t.text "instruction_loc"
    t.string "questionnaire_type"
  end

  create_table "quiz_question_choices", id: :integer, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "question_id"
    t.text "txt"
    t.boolean "is_correct", default: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "response_maps", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "reviewed_object_id", default: 0
    t.integer "reviewer_id", default: 0
    t.integer "reviewee_id", default: 0
    t.string "type"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "for_calibration", default: false, null: false
    t.boolean "reviewing_is_done_by_teams", default: false, null: false
    t.index ["reviewer_id"], name: "fk_response_map_reviewer"
  end

  create_table "responses", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "response_map_id", default: 0
    t.text "additional_comment"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "version_num"
    t.integer "round"
    t.boolean "is_submitted", default: false
    t.text "visibility"
    t.index ["response_map_id"], name: "fk_response_response_map"
  end

  create_table "resubmission_times", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "participant_id"
    t.datetime "resubmitted_at", precision: nil
    t.index ["participant_id"], name: "fk_resubmission_times_participants"
  end

  create_table "review_bids", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "priority"
    t.bigint "project_topic_id"
    t.bigint "participant_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.bigint "user_id"
    t.bigint "assignment_id"
    t.index ["assignment_id"], name: "fk_rails_549e23ae08"
    t.index ["participant_id"], name: "fk_rails_ab93feeb35"
    t.index ["project_topic_id"], name: "fk_rails_e88fa4058f"
    t.index ["user_id"], name: "fk_rails_6041e1cdb9"
  end

  create_table "review_comment_paste_bins", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "review_grade_id"
    t.string "title"
    t.text "review_comment", size: :medium
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["review_grade_id"], name: "fk_rails_0a539bcc81"
  end

  create_table "review_grades", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "participant_id"
    t.float "grade_for_reviewer"
    t.text "comment_for_reviewer", size: :medium
    t.integer "grader_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["participant_id"], name: "fk_rails_29587cf6a9"
  end

  create_table "roles", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "name"
    t.bigint "parent_id"
    t.text "description"
    t.integer "default_page_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["default_page_id"], name: "fk_role_default_page_id"
    t.index ["parent_id"], name: "fk_role_parent_id"
  end

  create_table "roles_permissions", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "role_id"
    t.integer "permission_id"
    t.index ["permission_id"], name: "fk_roles_permission_permission_id"
    t.index ["role_id"], name: "fk_roles_permission_role_id"
  end

  create_table "sample_reviews", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "assignment_id"
    t.integer "response_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "signed_up_teams", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "project_topic_id"
    t.bigint "team_id"
    t.boolean "is_waitlisted"
    t.integer "preference_priority_number"
    t.text "comments_for_advertisement"
    t.boolean "advertise_for_partner"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["project_topic_id"], name: "fk_signed_up_users_sign_up_topics"
    t.index ["team_id"], name: "fk_canon_signed_up_teams_team_id"
  end

  create_table "submission_records", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.text "record_type"
    t.text "content"
    t.string "operation"
    t.integer "team_id"
    t.string "submitted_by"
    t.integer "assignment_id"
  end

  create_table "suggestion_comments", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.text "comments"
    t.string "commenter"
    t.string "vote"
    t.integer "suggestion_id"
    t.datetime "created_at", precision: nil
    t.boolean "visible_to_student", default: false
    t.datetime "updated_at", precision: nil
  end

  create_table "suggestions", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "assignment_id"
    t.string "title"
    t.text "description"
    t.string "status"
    t.string "username"
    t.string "signup_preference"
  end

  create_table "survey_deployments", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "questionnaire_id"
    t.datetime "start_date", precision: nil
    t.datetime "end_date", precision: nil
    t.datetime "last_reminder", precision: nil
    t.integer "parent_id", default: 0
    t.integer "global_survey_id"
    t.text "type"
    t.string "deployment_type"
    t.index ["questionnaire_id"], name: "fk_rails_7c62b6ef2b"
  end

  create_table "ta_mappings", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "course_id"
    t.bigint "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["course_id"], name: "fk_ta_mappings_course_id"
    t.index ["user_id"], name: "index_ta_mappings_on_user_id"
  end

  create_table "tag_prompt_deployments", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "tag_prompt_id"
    t.bigint "assignment_id"
    t.bigint "questionnaire_id"
    t.string "question_type"
    t.integer "answer_length_threshold"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["assignment_id"], name: "index_tag_prompt_deployments_on_assignment_id"
    t.index ["questionnaire_id"], name: "index_tag_prompt_deployments_on_questionnaire_id"
    t.index ["tag_prompt_id"], name: "index_tag_prompt_deployments_on_tag_prompt_id"
  end

  create_table "tag_prompts", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "prompt"
    t.string "desc"
    t.string "control_type"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "teams", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "name"
    t.integer "parent_id"
    t.string "type"
    t.text "submitted_hyperlinks"
    t.integer "directory_num"
    t.integer "grade_for_submission"
    t.text "comment_for_submission"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "teams_participants", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "team_id"
    t.integer "user_id"
    t.integer "duty_id"
    t.bigint "participant_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["duty_id"], name: "index_teams_participants_on_duty_id"
    t.index ["participant_id"], name: "fk_rails_7192605c92"
    t.index ["team_id"], name: "fk_users_teams"
    t.index ["user_id"], name: "fk_teams_users"
  end

  create_table "teams_users", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "team_id"
    t.bigint "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["team_id"], name: "index_teams_users_on_team_id"
    t.index ["user_id"], name: "index_teams_users_on_user_id"
  end

  create_table "topic_bids", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "topic_id"
    t.integer "team_id"
    t.integer "priority"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "track_notifications", charset: "utf8mb4", collation: "utf8mb4_general_ci", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.integer "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "notification_id"
    t.index ["notification_id"], name: "notification_id"
    t.index ["user_id"], name: "user_id"
  end

  create_table "tree_folders", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "name"
    t.string "child_type"
    t.integer "parent_id"
  end

  create_table "user_pastebins", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "user_id"
    t.string "short_form"
    t.text "long_form", size: :medium
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "username"
    t.bigint "role_id"
    t.string "name"
    t.string "email"
    t.bigint "parent_id"
    t.boolean "private_by_default"
    t.boolean "email_on_submission", default: false
    t.boolean "is_new_user", default: true
    t.string "handle"
    t.string "time_zone_pref"
    t.text "public_key", size: :medium
    t.boolean "copy_of_emails", default: false
    t.bigint "institution_id"
    t.boolean "etc_icons_on_homepage", default: false
    t.integer "locale"
    t.string "password_digest"
    t.string "mru_directory_path"
    t.boolean "email_on_review", default: false
    t.boolean "email_on_review_of_review", default: false
    t.boolean "master_permission_granted", default: false
    t.string "persistence_token"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["institution_id"], name: "fk_canon_users_institution_id"
    t.index ["parent_id"], name: "fk_canon_users_parent_id"
    t.index ["role_id"], name: "fk_user_role_id"
  end

  create_table "wiki_types", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "name", default: "", null: false
  end

  add_foreign_key "account_requests", "institutions", name: "fk_canon_account_requests_institution_id"
  add_foreign_key "account_requests", "roles", name: "fk_canon_account_requests_role_id"
  add_foreign_key "answer_tags", "answers", name: "fk_canon_answer_tags_answer_id"
  add_foreign_key "answer_tags", "tag_prompt_deployments", name: "fk_canon_answer_tags_tag_prompt_deployment_id"
  add_foreign_key "answer_tags", "users", name: "fk_canon_answer_tags_user_id"
  add_foreign_key "assignments", "courses", name: "fk_canon_assignments_course_id"
  add_foreign_key "assignments", "users", column: "instructor_id", name: "fk_canon_assignments_instructor_id"
  add_foreign_key "assignments_duties", "assignments", name: "fk_canon_assignments_duties_assignment_id"
  add_foreign_key "courses", "institutions", name: "fk_canon_courses_institution_id"
  add_foreign_key "courses", "users", column: "instructor_id", name: "fk_canon_courses_instructor_id"
  add_foreign_key "duties", "users", column: "instructor_id", name: "fk_canon_duties_instructor_id"
  add_foreign_key "invitations", "participants", column: "from_id", name: "fk_canon_invitations_from_id"
  add_foreign_key "invitations", "participants", column: "to_id", name: "fk_canon_invitations_to_id"
  add_foreign_key "items", "questionnaires", name: "fk_canon_items_questionnaire_id"
  add_foreign_key "late_policies", "users", column: "instructor_id", name: "fk_canon_late_policies_instructor_id"
  add_foreign_key "participants", "join_team_requests", name: "fk_canon_participants_join_team_request_id"
  add_foreign_key "participants", "teams", name: "fk_canon_participants_team_id"
  add_foreign_key "participants", "users", name: "fk_canon_participants_user_id"
  add_foreign_key "project_topics", "assignments", name: "fk_canon_project_topics_assignment_id"
  add_foreign_key "question_advice", "items", column: "question_id", name: "fk_canon_question_advice_question_id"
  add_foreign_key "resubmission_times", "participants", name: "fk_canon_resubmission_times_participant_id"
  add_foreign_key "review_bids", "assignments", name: "fk_canon_review_bids_assignment_id"
  add_foreign_key "review_bids", "participants", name: "fk_canon_review_bids_participant_id"
  add_foreign_key "review_bids", "users", name: "fk_canon_review_bids_user_id"
  add_foreign_key "review_comment_paste_bins", "review_grades", name: "fk_canon_review_comment_paste_bins_review_grade_id"
  add_foreign_key "review_grades", "participants", name: "fk_canon_review_grades_participant_id"
  add_foreign_key "roles", "roles", column: "parent_id", name: "fk_canon_roles_parent_id", on_delete: :cascade
  add_foreign_key "signed_up_teams", "project_topics", name: "fk_canon_signed_up_teams_project_topic_id"
  add_foreign_key "signed_up_teams", "teams", name: "fk_canon_signed_up_teams_team_id"
  add_foreign_key "survey_deployments", "questionnaires", name: "fk_canon_survey_deployments_questionnaire_id"
  add_foreign_key "ta_mappings", "courses", name: "fk_canon_ta_mappings_course_id"
  add_foreign_key "ta_mappings", "users", name: "fk_canon_ta_mappings_user_id"
  add_foreign_key "tag_prompt_deployments", "assignments", name: "fk_canon_tag_prompt_deployments_assignment_id"
  add_foreign_key "tag_prompt_deployments", "questionnaires", name: "fk_canon_tag_prompt_deployments_questionnaire_id"
  add_foreign_key "tag_prompt_deployments", "tag_prompts", name: "fk_canon_tag_prompt_deployments_tag_prompt_id"
  add_foreign_key "teams_participants", "participants", name: "fk_canon_teams_participants_participant_id"
  add_foreign_key "teams_participants", "teams", name: "fk_canon_teams_participants_team_id"
  add_foreign_key "teams_users", "teams", name: "fk_canon_teams_users_team_id"
  add_foreign_key "teams_users", "users", name: "fk_canon_teams_users_user_id"
  add_foreign_key "users", "institutions", name: "fk_canon_users_institution_id"
  add_foreign_key "users", "roles", name: "fk_canon_users_role_id"
  add_foreign_key "users", "users", column: "parent_id", name: "fk_canon_users_parent_id"
end
