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

ActiveRecord::Schema[8.1].define(version: 2025_10_29_071649) do
  create_table "account_requests", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "full_name"
    t.bigint "institution_id", null: false
    t.text "introduction"
    t.bigint "role_id", null: false
    t.string "status"
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["institution_id"], name: "index_account_requests_on_institution_id"
    t.index ["role_id"], name: "index_account_requests_on_role_id"
  end

  create_table "answers", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "answer"
    t.text "comments"
    t.datetime "created_at", null: false
    t.integer "item_id", default: 0, null: false
    t.integer "response_id"
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "fk_score_items"
    t.index ["response_id"], name: "fk_score_response"
  end

  create_table "assignment_questionnaires", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "assignment_id"
    t.datetime "created_at", null: false
    t.integer "notification_limit", default: 15, null: false
    t.integer "questionnaire_id"
    t.integer "questionnaire_weight"
    t.datetime "updated_at", null: false
    t.integer "used_in_round"
    t.index ["assignment_id"], name: "fk_aq_assignments_id"
    t.index ["questionnaire_id"], name: "fk_aq_questionnaire_id"
  end

  create_table "assignments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.boolean "allow_selecting_additional_reviews_after_1st_round"
    t.boolean "allow_suggestions"
    t.boolean "availability_flag"
    t.boolean "calculate_penalty"
    t.boolean "can_choose_topic_to_review"
    t.boolean "can_review_same_topic"
    t.boolean "copy_flag"
    t.bigint "course_id"
    t.datetime "created_at", null: false
    t.integer "days_between_submissions"
    t.string "directory_path"
    t.boolean "enable_pair_programming", default: false
    t.boolean "has_badge"
    t.boolean "has_teams", default: false
    t.boolean "has_topics", default: false
    t.bigint "instructor_id", null: false
    t.boolean "is_anonymous"
    t.boolean "is_answer_tagging_allowed"
    t.boolean "is_calibrated"
    t.boolean "is_coding_assignment"
    t.boolean "is_intelligent"
    t.boolean "is_penalty_calculated"
    t.boolean "is_selfreview_enabled"
    t.integer "late_policy_id"
    t.integer "max_bids"
    t.integer "max_reviews_per_submission"
    t.integer "max_team_size"
    t.boolean "microtask"
    t.string "name"
    t.integer "num_metareviews_allowed"
    t.integer "num_metareviews_required"
    t.integer "num_quiz_questions"
    t.integer "num_review_of_reviewers"
    t.integer "num_review_of_reviews"
    t.integer "num_reviewers"
    t.integer "num_reviews"
    t.integer "num_reviews_allowed"
    t.integer "num_reviews_required"
    t.boolean "private"
    t.string "reputation_algorithm"
    t.boolean "require_quiz"
    t.string "review_assignment_strategy"
    t.integer "review_topic_threshold"
    t.boolean "reviews_visible_to_all"
    t.integer "rounds_of_reviews"
    t.integer "sample_assignment_id"
    t.boolean "show_teammate_reviews"
    t.integer "simicheck"
    t.integer "simicheck_threshold"
    t.text "spec_location"
    t.boolean "staggered_deadline"
    t.integer "submitter_count"
    t.datetime "updated_at", null: false
    t.boolean "use_bookmark"
    t.index ["course_id"], name: "index_assignments_on_course_id"
    t.index ["instructor_id"], name: "index_assignments_on_instructor_id"
  end

  create_table "bookmark_ratings", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "bookmark_id"
    t.datetime "created_at", null: false
    t.integer "rating"
    t.datetime "updated_at", null: false
    t.integer "user_id"
  end

  create_table "bookmarks", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.text "title"
    t.integer "topic_id"
    t.datetime "updated_at", null: false
    t.text "url"
    t.integer "user_id"
  end

  create_table "cakes", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "courses", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "directory_path"
    t.text "info"
    t.bigint "institution_id", null: false
    t.bigint "instructor_id", null: false
    t.string "name"
    t.boolean "private", default: false
    t.datetime "updated_at", null: false
    t.index ["institution_id"], name: "index_courses_on_institution_id"
    t.index ["instructor_id"], name: "fk_course_users"
    t.index ["instructor_id"], name: "index_courses_on_instructor_id"
  end

  create_table "due_dates", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "deadline_name"
    t.integer "deadline_type_id", null: false
    t.string "delayed_job_id"
    t.string "description_url"
    t.datetime "due_at", null: false
    t.boolean "flag", default: false
    t.bigint "parent_id", null: false
    t.string "parent_type", null: false
    t.integer "quiz_allowed_id", default: 1
    t.integer "rereview_allowed_id"
    t.integer "resubmission_allowed_id"
    t.integer "review_allowed_id", null: false
    t.integer "review_of_review_allowed_id"
    t.integer "round"
    t.integer "submission_allowed_id", null: false
    t.integer "teammate_review_allowed_id", default: 3
    t.integer "threshold", default: 1
    t.string "type", default: "AssignmentDueDate"
    t.datetime "updated_at", null: false
    t.index ["parent_type", "parent_id"], name: "index_due_dates_on_parent"
  end

  create_table "institutions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "invitations", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "assignment_id"
    t.datetime "created_at", null: false
    t.bigint "from_id", null: false
    t.bigint "participant_id", null: false
    t.string "reply_status", limit: 1
    t.bigint "to_id", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_id"], name: "fk_invitation_assignments"
    t.index ["from_id"], name: "index_invitations_on_from_id"
    t.index ["participant_id"], name: "index_invitations_on_participant_id"
    t.index ["to_id"], name: "index_invitations_on_to_id"
  end

  create_table "items", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "alternatives"
    t.boolean "break_before"
    t.datetime "created_at", null: false
    t.string "max_label"
    t.string "min_label"
    t.string "question_type"
    t.bigint "questionnaire_id", null: false
    t.decimal "seq", precision: 10
    t.string "size"
    t.text "txt"
    t.datetime "updated_at", null: false
    t.integer "weight"
    t.index ["questionnaire_id"], name: "fk_question_questionnaires"
    t.index ["questionnaire_id"], name: "index_items_on_questionnaire_id"
  end

  create_table "join_team_requests", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.text "comments"
    t.datetime "created_at", null: false
    t.integer "participant_id"
    t.string "reply_status"
    t.integer "team_id"
    t.datetime "updated_at", null: false
  end

  create_table "nodes", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "node_object_id"
    t.integer "parent_id"
    t.string "type"
    t.datetime "updated_at", null: false
  end

  create_table "participants", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "authorization"
    t.boolean "can_mentor"
    t.boolean "can_review", default: true
    t.boolean "can_submit", default: true
    t.boolean "can_take_quiz"
    t.datetime "created_at", null: false
    t.string "current_stage"
    t.float "grade"
    t.string "handle"
    t.bigint "join_team_request_id"
    t.integer "parent_id", null: false
    t.boolean "permission_granted", default: false
    t.datetime "stage_deadline"
    t.bigint "team_id"
    t.string "topic"
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["join_team_request_id"], name: "index_participants_on_join_team_request_id"
    t.index ["team_id"], name: "index_participants_on_team_id"
    t.index ["user_id"], name: "fk_participant_users"
    t.index ["user_id"], name: "index_participants_on_user_id"
  end

  create_table "question_advices", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.text "advice"
    t.datetime "created_at", null: false
    t.bigint "question_id", null: false
    t.integer "score"
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_question_advices_on_question_id"
  end

  create_table "question_types", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "questionnaire_types", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "questionnaires", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "display_type"
    t.text "instruction_loc"
    t.integer "instructor_id"
    t.integer "max_question_score"
    t.integer "min_question_score"
    t.string "name"
    t.boolean "private"
    t.string "questionnaire_type"
    t.datetime "updated_at", null: false
  end

  create_table "quiz_question_choices", id: :integer, charset: "latin1", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "iscorrect", default: false
    t.integer "question_id"
    t.text "txt"
    t.datetime "updated_at", null: false
  end

  create_table "response_maps", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "for_calibration", default: false, null: false
    t.integer "reviewed_object_id", default: 0, null: false
    t.integer "reviewee_id", default: 0, null: false
    t.integer "reviewer_id", default: 0, null: false
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["reviewer_id"], name: "fk_response_map_reviewer"
  end

  create_table "responses", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.text "additional_comment"
    t.datetime "created_at", null: false
    t.boolean "is_submitted", default: false
    t.integer "map_id", default: 0, null: false
    t.integer "round"
    t.datetime "updated_at", null: false
    t.integer "version_num"
    t.index ["map_id"], name: "fk_response_response_map"
  end

  create_table "roles", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "default_page_id"
    t.string "name"
    t.bigint "parent_id"
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "fk_rails_4404228d2f"
  end

  create_table "sign_up_topics", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "assignment_id", null: false
    t.text "category"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "link"
    t.integer "max_choosers", default: 0, null: false
    t.integer "micropayment", default: 0
    t.integer "private_to"
    t.string "topic_identifier", limit: 10
    t.text "topic_name", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_id"], name: "fk_sign_up_categories_sign_up_topics"
    t.index ["assignment_id"], name: "index_sign_up_topics_on_assignment_id"
  end

  create_table "signed_up_teams", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.boolean "advertise_for_partner"
    t.text "comments_for_advertisement"
    t.datetime "created_at", null: false
    t.boolean "is_waitlisted"
    t.integer "preference_priority_number"
    t.bigint "sign_up_topic_id", null: false
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.index ["sign_up_topic_id"], name: "index_signed_up_teams_on_sign_up_topic_id"
    t.index ["team_id"], name: "index_signed_up_teams_on_team_id"
  end

  create_table "ta_mappings", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "course_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["course_id"], name: "index_ta_mappings_on_course_id"
    t.index ["user_id"], name: "fk_ta_mapping_users"
    t.index ["user_id"], name: "index_ta_mappings_on_user_id"
  end

  create_table "teams", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "comment_for_submission"
    t.datetime "created_at", null: false
    t.integer "grade_for_submission"
    t.string "name", null: false
    t.integer "parent_id", null: false
    t.string "type", null: false
    t.datetime "updated_at", null: false
  end

  create_table "teams_participants", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "duty_id"
    t.bigint "participant_id", null: false
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["participant_id"], name: "index_teams_participants_on_participant_id"
    t.index ["team_id"], name: "index_teams_participants_on_team_id"
    t.index ["user_id"], name: "index_teams_participants_on_user_id"
  end

  create_table "teams_users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["team_id"], name: "index_teams_users_on_team_id"
    t.index ["user_id"], name: "index_teams_users_on_user_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.boolean "copy_of_emails", default: false
    t.datetime "created_at", null: false
    t.string "email"
    t.boolean "email_on_review", default: false
    t.boolean "email_on_review_of_review", default: false
    t.boolean "email_on_submission", default: false
    t.boolean "etc_icons_on_homepage", default: false
    t.string "full_name"
    t.string "handle"
    t.bigint "institution_id"
    t.boolean "is_new_user", default: true
    t.integer "locale"
    t.boolean "master_permission_granted", default: false
    t.string "mru_directory_path"
    t.string "name"
    t.bigint "parent_id"
    t.string "password_digest"
    t.string "persistence_token"
    t.bigint "role_id", null: false
    t.string "timeZonePref"
    t.datetime "updated_at", null: false
    t.index ["institution_id"], name: "index_users_on_institution_id"
    t.index ["parent_id"], name: "index_users_on_parent_id"
    t.index ["role_id"], name: "index_users_on_role_id"
  end

  add_foreign_key "account_requests", "institutions"
  add_foreign_key "account_requests", "roles"
  add_foreign_key "assignments", "courses"
  add_foreign_key "assignments", "users", column: "instructor_id"
  add_foreign_key "courses", "institutions"
  add_foreign_key "courses", "users", column: "instructor_id"
  add_foreign_key "invitations", "participants", column: "from_id"
  add_foreign_key "invitations", "participants", column: "to_id"
  add_foreign_key "items", "questionnaires"
  add_foreign_key "participants", "join_team_requests"
  add_foreign_key "participants", "teams"
  add_foreign_key "participants", "users"
  add_foreign_key "question_advices", "items", column: "question_id"
  add_foreign_key "roles", "roles", column: "parent_id", on_delete: :cascade
  add_foreign_key "sign_up_topics", "assignments"
  add_foreign_key "signed_up_teams", "sign_up_topics"
  add_foreign_key "signed_up_teams", "teams"
  add_foreign_key "ta_mappings", "courses"
  add_foreign_key "ta_mappings", "users"
  add_foreign_key "teams_participants", "participants"
  add_foreign_key "teams_participants", "teams"
  add_foreign_key "teams_users", "teams"
  add_foreign_key "teams_users", "users"
  add_foreign_key "users", "institutions"
  add_foreign_key "users", "roles"
  add_foreign_key "users", "users", column: "parent_id"
end
