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

ActiveRecord::Schema[8.0].define(version: 2026_03_20_011304) do
  create_table "account_requests", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "username"
    t.string "full_name"
    t.string "email"
    t.string "status"
    t.text "introduction"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "role_id", null: false
    t.bigint "institution_id", null: false
    t.index ["institution_id"], name: "index_account_requests_on_institution_id"
    t.index ["role_id"], name: "index_account_requests_on_role_id"
  end

  create_table "answer_tags", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "answer_id"
    t.bigint "tag_prompt_deployment_id"
    t.bigint "user_id"
    t.string "value"
    t.decimal "confidence_level", precision: 10, scale: 5
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["answer_id"], name: "fk_rails_6c5d47c4e2"
    t.index ["tag_prompt_deployment_id"], name: "fk_rails_ec0fee5d79"
    t.index ["user_id"], name: "fk_rails_36ff09eab9"
  end

  create_table "answers", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "item_id", default: 0, null: false
    t.integer "response_id"
    t.integer "answer"
    t.text "comments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "fk_score_items"
    t.index ["response_id"], name: "fk_score_response"
  end

  create_table "assignment_questionnaires", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "assignment_id"
    t.integer "questionnaire_id"
    t.integer "notification_limit", default: 15, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "used_in_round"
    t.integer "questionnaire_weight"
    t.index ["assignment_id"], name: "fk_aq_assignments_id"
    t.index ["questionnaire_id"], name: "fk_aq_questionnaire_id"
  end

  create_table "assignments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.string "directory_path"
    t.integer "submitter_count"
    t.boolean "private"
    t.integer "num_reviews"
    t.integer "num_review_of_reviews"
    t.integer "num_review_of_reviewers"
    t.boolean "reviews_visible_to_all"
    t.integer "num_reviewers"
    t.text "URL"
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
    t.boolean "topics_assigned_by_bidding"
    t.boolean "calculate_penalty"
    t.integer "late_policy_id"
    t.boolean "is_penalty_calculated"
    t.boolean "show_teammate_reviews"
    t.boolean "available_to_students"
    t.boolean "can_bookmark_topics"
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "instructor_id", null: false
    t.bigint "course_id"
    t.boolean "enable_pair_programming", default: false
    t.boolean "has_teams", default: false
    t.boolean "has_topics", default: false
    t.boolean "vary_by_round", default: false, null: false
    t.index ["course_id"], name: "index_assignments_on_course_id"
    t.index ["instructor_id"], name: "index_assignments_on_instructor_id"
  end

  create_table "assignments_duties", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "assignment_id", null: false
    t.bigint "duty_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_id"], name: "index_assignments_duties_on_assignment_id"
    t.index ["duty_id"], name: "index_assignments_duties_on_duty_id"
  end

  create_table "bookmark_ratings", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "artifact_id"
    t.integer "rater_id"
    t.integer "ratings"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "bookmarks", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.text "url"
    t.text "title"
    t.text "description"
    t.integer "user_id"
    t.integer "topic_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "cakes", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "courses", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.string "directory_path"
    t.text "info"
    t.boolean "is_private", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "instructor_id", null: false
    t.bigint "institution_id", null: false
    t.index ["institution_id"], name: "index_courses_on_institution_id"
    t.index ["instructor_id"], name: "fk_course_users"
    t.index ["instructor_id"], name: "index_courses_on_instructor_id"
  end

  create_table "deadline_rights", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
  end

  create_table "deadline_types", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
  end

  create_table "due_dates", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "due_at", null: false
    t.integer "deadline_type_id", null: false
    t.string "parent_type", null: false
    t.bigint "assignment_id", null: false
    t.integer "submission_allowed_id", null: false
    t.integer "review_allowed_id", null: false
    t.integer "round"
    t.boolean "flag", default: false
    t.integer "threshold", default: 1
    t.string "delayed_job_id"
    t.string "deadline_name"
    t.string "description_url"
    t.integer "quiz_allowed_id", default: 1
    t.integer "teammate_review_allowed_id", default: 3
    t.string "type", default: "AssignmentDueDate"
    t.integer "resubmission_allowed_id"
    t.integer "rereview_allowed_id"
    t.integer "review_of_review_allowed_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_type", "assignment_id"], name: "index_due_dates_on_parent"
  end

  create_table "duties", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.boolean "private", default: false
    t.bigint "instructor_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "max_members_for_duty"
    t.index ["instructor_id"], name: "index_duties_on_instructor_id"
  end

  create_table "institutions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "invitations", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "assignment_id"
    t.string "reply_status", limit: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "from_id", null: false
    t.bigint "to_id", null: false
    t.index ["assignment_id"], name: "fk_invitation_assignments"
    t.index ["from_id"], name: "index_invitations_on_from_id"
    t.index ["to_id"], name: "index_invitations_on_to_id"
  end

  create_table "items", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.text "txt"
    t.integer "weight"
    t.decimal "seq", precision: 10
    t.string "question_type"
    t.string "size"
    t.string "alternatives"
    t.boolean "break_before"
    t.string "max_label"
    t.string "min_label"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "questionnaire_id", null: false
    t.index ["questionnaire_id"], name: "fk_question_questionnaires"
    t.index ["questionnaire_id"], name: "index_items_on_questionnaire_id"
  end

  create_table "join_team_requests", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "participant_id"
    t.integer "team_id"
    t.text "comments"
    t.string "reply_status"
  end

  create_table "languages", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
  end

  create_table "late_policies", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.float "penalty_per_unit"
    t.integer "max_penalty", default: 0, null: false
    t.string "penalty_unit", null: false
    t.integer "times_used", default: 0, null: false
    t.bigint "instructor_id"
    t.string "policy_name"
    t.boolean "private", default: true
    t.index ["instructor_id"], name: "fk_rails_c0d822b6f4"
  end

  create_table "nodes", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "parent_id"
    t.integer "node_object_id"
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "participants", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "can_submit", default: true
    t.boolean "can_review", default: true
    t.string "handle"
    t.boolean "OK_to_show", default: false
    t.bigint "join_team_request_id"
    t.bigint "team_id"
    t.string "topic"
    t.string "current_stage"
    t.datetime "stage_deadline"
    t.boolean "can_take_quiz"
    t.boolean "can_mentor"
    t.string "authorization"
    t.integer "parent_id", null: false
    t.string "type", null: false
    t.float "grade"
    t.index ["join_team_request_id"], name: "index_participants_on_join_team_request_id"
    t.index ["team_id"], name: "index_participants_on_team_id"
    t.index ["user_id"], name: "fk_participant_users"
    t.index ["user_id"], name: "index_participants_on_user_id"
  end

  create_table "password_resets", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "user_email"
    t.string "token"
    t.datetime "updated_at"
  end

  create_table "permissions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
  end

  create_table "project_topics", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.text "topic_name", null: false
    t.bigint "assignment_id", null: false
    t.integer "max_choosers", default: 0, null: false
    t.text "category"
    t.string "topic_identifier", limit: 10
    t.integer "micropayment", default: 0
    t.integer "private_to"
    t.text "description"
    t.string "link"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_id"], name: "index_project_topics_on_assignment_id"
  end

  create_table "question_advice", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "question_id", null: false
    t.integer "score"
    t.text "advice"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_question_advice_on_question_id"
  end

  create_table "question_types", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "questionnaire_types", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "questionnaires", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.integer "instructor_id"
    t.boolean "private"
    t.integer "min_question_score"
    t.integer "max_question_score"
    t.string "questionnaire_type"
    t.string "display_type"
    t.text "instruction_loc"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "quiz_question_choices", id: :integer, charset: "latin1", force: :cascade do |t|
    t.integer "question_id"
    t.text "txt"
    t.boolean "iscorrect", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "response_maps", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "reviewed_object_id", default: 0, null: false
    t.integer "reviewer_id", default: 0, null: false
    t.integer "reviewee_id", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type"
    t.index ["reviewer_id"], name: "fk_response_map_reviewer"
  end

  create_table "responses", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "response_map_id", default: 0, null: false
    t.text "additional_comment"
    t.boolean "is_submitted", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "round"
    t.integer "version_num"
    t.index ["response_map_id"], name: "fk_response_response_map"
  end

  create_table "resubmission_times", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "participant_id"
    t.datetime "resubmitted_at"
    t.index ["participant_id"], name: "fk_rails_8a569f5ab6"
  end

  create_table "review_bids", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "priority"
    t.bigint "project_topic_id"
    t.bigint "participant_id"
    t.bigint "user_id"
    t.bigint "assignment_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_id"], name: "fk_rails_549e23ae08"
    t.index ["participant_id"], name: "fk_rails_ab93feeb35"
    t.index ["user_id"], name: "fk_rails_6041e1cdb9"
  end

  create_table "review_comment_paste_bins", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "review_grade_id"
    t.string "title"
    t.text "review_comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["review_grade_id"], name: "fk_rails_0a539bcc81"
  end

  create_table "review_grades", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "participant_id"
    t.integer "grade_for_reviewer"
    t.text "comment_for_reviewer"
    t.datetime "review_graded_at"
    t.integer "reviewer_id"
    t.index ["participant_id"], name: "fk_rails_29587cf6a9"
  end

  create_table "roles", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.bigint "parent_id"
    t.integer "default_page_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "fk_rails_4404228d2f"
  end

  create_table "roles_permissions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "role_id"
    t.integer "permission_id"
  end

  create_table "sample_reviews", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "assignment_id"
    t.integer "response_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "signed_up_teams", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "project_topic_id", null: false
    t.bigint "team_id", null: false
    t.boolean "is_waitlisted"
    t.integer "preference_priority_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "comments_for_advertisement"
    t.boolean "advertise_for_partner"
    t.index ["project_topic_id"], name: "index_signed_up_teams_on_project_topic_id"
    t.index ["team_id"], name: "index_signed_up_teams_on_team_id"
  end

  create_table "submission_records", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.text "record_type"
    t.text "content"
    t.string "operation"
    t.integer "team_id"
    t.string "submitted_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "suggestion_comments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.text "comments"
    t.string "commenter"
    t.string "vote"
    t.integer "suggestion_id"
    t.boolean "visible_to_student", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "suggestions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "assignment_id"
    t.string "title"
    t.text "description"
    t.string "status"
    t.string "username"
    t.string "signup_preference"
  end

  create_table "survey_deployments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "questionnaire_id"
    t.datetime "start_date"
    t.datetime "end_date"
    t.datetime "last_reminder"
    t.integer "parent_id", default: 0
    t.integer "global_survey_id"
    t.string "deployment_type"
    t.index ["questionnaire_id"], name: "fk_rails_7c62b6ef2b"
  end

  create_table "ta_mappings", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "course_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_ta_mappings_on_course_id"
    t.index ["user_id"], name: "fk_ta_mapping_users"
    t.index ["user_id"], name: "index_ta_mappings_on_user_id"
  end

  create_table "tag_prompt_deployments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "tag_prompt_id"
    t.bigint "assignment_id"
    t.bigint "questionnaire_id"
    t.string "question_type"
    t.integer "answer_length_threshold"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_id"], name: "fk_rails_7a44de7225"
    t.index ["questionnaire_id"], name: "fk_rails_c3b5a3cf6f"
    t.index ["tag_prompt_id"], name: "fk_rails_fbf75bc17c"
  end

  create_table "tag_prompts", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "prompt"
    t.string "desc"
    t.string "control_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "teams", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", null: false
    t.string "type", null: false
    t.integer "parent_id", null: false
    t.integer "grade_for_submission"
    t.string "comment_for_submission"
    t.text "submitted_hyperlinks"
    t.integer "directory_num"
  end

  create_table "teams_participants", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "team_id", null: false
    t.integer "duty_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "participant_id", null: false
    t.integer "user_id", null: false
    t.index ["participant_id"], name: "index_teams_participants_on_participant_id"
    t.index ["team_id"], name: "index_teams_participants_on_team_id"
    t.index ["user_id"], name: "index_teams_participants_on_user_id"
  end

  create_table "teams_users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "team_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_teams_users_on_team_id"
    t.index ["user_id"], name: "index_teams_users_on_user_id"
  end

  create_table "topic_bids", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "topic_id"
    t.integer "team_id"
    t.integer "priority"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "track_notifications", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "notification_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tree_folders", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.string "child_type"
    t.integer "parent_id"
  end

  create_table "user_pastebins", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "user_id"
    t.string "short_form"
    t.text "long_form"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "username"
    t.string "password_digest"
    t.string "full_name"
    t.string "email"
    t.boolean "email_on_submission", default: false
    t.boolean "is_new_user", default: true
    t.string "handle"
    t.string "timeZonePref"
    t.boolean "copy_of_emails", default: false
    t.boolean "etc_icons_on_homepage", default: false
    t.integer "locale"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "institution_id"
    t.bigint "role_id", null: false
    t.bigint "parent_id"
    t.index ["institution_id"], name: "index_users_on_institution_id"
    t.index ["parent_id"], name: "index_users_on_parent_id"
    t.index ["role_id"], name: "index_users_on_role_id"
  end

  add_foreign_key "account_requests", "institutions"
  add_foreign_key "account_requests", "roles"
  add_foreign_key "answer_tags", "answers"
  add_foreign_key "answer_tags", "tag_prompt_deployments"
  add_foreign_key "answer_tags", "users"
  add_foreign_key "assignments", "courses"
  add_foreign_key "assignments", "users", column: "instructor_id"
  add_foreign_key "assignments_duties", "assignments"
  add_foreign_key "assignments_duties", "duties"
  add_foreign_key "courses", "institutions"
  add_foreign_key "courses", "users", column: "instructor_id"
  add_foreign_key "duties", "users", column: "instructor_id"
  add_foreign_key "invitations", "participants", column: "from_id"
  add_foreign_key "invitations", "participants", column: "to_id"
  add_foreign_key "items", "questionnaires"
  add_foreign_key "late_policies", "users", column: "instructor_id"
  add_foreign_key "participants", "join_team_requests"
  add_foreign_key "participants", "teams"
  add_foreign_key "participants", "users"
  add_foreign_key "project_topics", "assignments"
  add_foreign_key "question_advice", "items", column: "question_id"
  add_foreign_key "resubmission_times", "participants"
  add_foreign_key "review_bids", "assignments"
  add_foreign_key "review_bids", "participants"
  add_foreign_key "review_bids", "users"
  add_foreign_key "review_comment_paste_bins", "review_grades"
  add_foreign_key "review_grades", "participants"
  add_foreign_key "roles", "roles", column: "parent_id", on_delete: :cascade
  add_foreign_key "signed_up_teams", "project_topics"
  add_foreign_key "signed_up_teams", "teams"
  add_foreign_key "survey_deployments", "questionnaires"
  add_foreign_key "ta_mappings", "courses"
  add_foreign_key "ta_mappings", "users"
  add_foreign_key "tag_prompt_deployments", "assignments"
  add_foreign_key "tag_prompt_deployments", "questionnaires"
  add_foreign_key "tag_prompt_deployments", "tag_prompts"
  add_foreign_key "teams_participants", "participants"
  add_foreign_key "teams_participants", "teams"
  add_foreign_key "teams_users", "teams"
  add_foreign_key "teams_users", "users"
  add_foreign_key "users", "institutions"
  add_foreign_key "users", "roles"
  add_foreign_key "users", "users", column: "parent_id"
end
