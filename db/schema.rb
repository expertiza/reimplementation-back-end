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

ActiveRecord::Schema[7.0].define(version: 2023_03_15_185139) do
  create_table "assignments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.string "directory_path"
    t.integer "submitter_count"
    t.integer "course_id"
    t.integer "instructor_id"
    t.boolean "private"
    t.integer "num_reviews"
    t.integer "num_review_of_reviews"
    t.integer "num_review_of_reviewers"
    t.boolean "reviews_visible_to_all"
    t.integer "num_reviewers"
    t.text "spec_location"
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
    t.boolean "is_intelligent"
    t.boolean "calculate_penalty"
    t.integer "late_policy_id"
    t.boolean "is_penalty_calculated"
    t.integer "max_bids"
    t.boolean "show_teammate_reviews"
    t.boolean "availability_flag"
    t.boolean "use_bookmark"
    t.boolean "can_review_same_topic"
    t.boolean "can_choose_topic_to_review"
    t.boolean "is_calibrated"
    t.boolean "is_selfreview_enabled"
    t.string "reputation_algorithm"
    t.boolean "is_anonymous"
    t.integer "num_reviews_required"
    t.integer "num_metareviews_required"
    t.integer "num_metareviews_allowed"
    t.integer "num_reviews_allowed"
    t.integer "simicheck"
    t.integer "simicheck_threshold"
    t.boolean "is_answer_tagging_allowed"
    t.boolean "has_badge"
    t.boolean "allow_selecting_additional_reviews_after_1st_round"
    t.integer "sample_assignment_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "institutions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "roles", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.bigint "parent_id"
    t.integer "default_page_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "fk_rails_4404228d2f"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.string "password_digest"
    t.integer "role_id"
    t.string "fullname"
    t.string "email"
    t.integer "parent_id"
    t.string "mru_directory_path"
    t.boolean "email_on_review"
    t.boolean "email_on_submission"
    t.boolean "email_on_review_of_review"
    t.boolean "is_new_user"
    t.boolean "master_permission_granted"
    t.string "handle"
    t.string "persistence_token"
    t.string "timezonepref"
    t.boolean "copy_of_emails"
    t.integer "institution_id"
    t.boolean "etc_icons_on_homepage"
    t.integer "locale"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "roles", "roles", column: "parent_id", on_delete: :cascade
end
