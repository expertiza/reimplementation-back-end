class InitFullSchema < ActiveRecord::Migration[8.0]
  def change

    # ----------------------------
    # CORE TABLES
    # ----------------------------
    create_table :tag_prompts do |t|
      t.string :prompt
      t.string :desc
      t.string :control_type
      t.timestamps
    end unless table_exists?(:tag_prompts)

    create_table :tag_prompt_deployments do |t|
      t.bigint :tag_prompt_id
      t.bigint :assignment_id
      t.bigint :questionnaire_id
      t.string :question_type
      t.integer :answer_length_threshold
      t.timestamps
    end unless table_exists?(:tag_prompt_deployments)

    create_table :answer_tags do |t|
      t.bigint :answer_id
      t.bigint :tag_prompt_deployment_id
      t.bigint :user_id
      t.string :value
      t.decimal :confidence_level, precision: 10, scale: 5
      t.timestamps
    end unless table_exists?(:answer_tags)

    create_table :topic_bids do |t|
      t.integer :topic_id
      t.integer :team_id
      t.integer :priority
      t.timestamps
    end unless table_exists?(:topic_bids)

    create_table :deadline_rights do |t|
      t.string :name
    end unless table_exists?(:deadline_rights)

    create_table :deadline_types do |t|
      t.string :name
    end unless table_exists?(:deadline_types)

    create_table :languages do |t|
      t.string :name
    end unless table_exists?(:languages)

    create_table :permissions do |t|
      t.string :name
    end unless table_exists?(:permissions)

    create_table :password_resets do |t|
      t.string :user_email
      t.string :token
      t.datetime :updated_at
    end unless table_exists?(:password_resets)

    create_table :sample_reviews do |t|
      t.integer :assignment_id
      t.integer :response_id
      t.timestamps
    end unless table_exists?(:sample_reviews)

    create_table :submission_records do |t|
      t.text :record_type   # FIXED (no STI)
      t.string :content
      t.string :operation
      t.integer :team_id
      t.string :submitted_by
      t.timestamps
    end unless table_exists?(:submission_records)

    create_table :suggestions do |t|
      t.integer :assignment_id
      t.string :title
      t.text :description
      t.string :status
      t.string :username
      t.string :signup_preference
    end unless table_exists?(:suggestions)

    create_table :suggestion_comments do |t|
      t.text :comments
      t.string :commenter
      t.string :vote
      t.integer :suggestion_id
      t.boolean :visible_to_student, default: false
      t.timestamps
    end unless table_exists?(:suggestion_comments)

    create_table :tree_folders do |t|
      t.string :name
      t.string :child_type
      t.integer :parent_id
    end unless table_exists?(:tree_folders)

    create_table :user_pastebins do |t|
      t.integer :user_id
      t.string :short_form
      t.text :long_form
      t.timestamps
    end unless table_exists?(:user_pastebins)

    create_table :duties do |t|
      t.string :name
      t.integer :max_members_for_duty
      t.bigint :assignment_id
      t.timestamps
    end unless table_exists?(:duties)

    create_table :late_policies do |t|
      t.float :penalty_per_unit
      t.integer :max_penalty, default: 0, null: false
      t.string :penalty_unit, null: false
      t.integer :times_used, default: 0, null: false
      t.bigint :instructor_id
      t.string :policy_name
      t.boolean :private, default: true
    end unless table_exists?(:late_policies)

    create_table :resubmission_times do |t|
      t.bigint :participant_id
      t.datetime :resubmitted_at
    end unless table_exists?(:resubmission_times)

    create_table :review_bids do |t|
      t.integer :priority
      t.bigint :project_topic_id
      t.bigint :participant_id
      t.bigint :user_id
      t.bigint :assignment_id
      t.timestamps
    end unless table_exists?(:review_bids)

    create_table :review_grades do |t|
      t.bigint :participant_id
      t.integer :grade_for_reviewer
      t.text :comment_for_reviewer
      t.datetime :review_graded_at
      t.integer :reviewer_id
    end unless table_exists?(:review_grades)

    create_table :review_comment_paste_bins do |t|
      t.bigint :review_grade_id
      t.string :title
      t.text :review_comment
      t.timestamps
    end unless table_exists?(:review_comment_paste_bins)

    create_table :roles_permissions do |t|
      t.integer :role_id
      t.integer :permission_id
    end unless table_exists?(:roles_permissions)

    create_table :survey_deployments do |t|
      t.bigint :questionnaire_id
      t.datetime :start_date
      t.datetime :end_date
      t.datetime :last_reminder
      t.integer :parent_id, default: 0
      t.integer :global_survey_id
      t.string :deployment_type   # FIXED
    end unless table_exists?(:survey_deployments)

    create_table :track_notifications do |t|
      t.integer :user_id
      t.integer :notification_id
      t.timestamps
    end unless table_exists?(:track_notifications)

    create_table :questionnaire_types do |t|
      t.string :display_type, null: false
    end unless table_exists?(:questionnaire_types)

    # ----------------------------
    # FOREIGN KEYS
    # ----------------------------
    add_foreign_key :tag_prompt_deployments, :tag_prompts if table_exists?(:tag_prompt_deployments)
    add_foreign_key :tag_prompt_deployments, :assignments if table_exists?(:assignments)
    add_foreign_key :tag_prompt_deployments, :questionnaires if table_exists?(:questionnaires)

    add_foreign_key :answer_tags, :answers if table_exists?(:answers)
    add_foreign_key :answer_tags, :users if table_exists?(:users)
    add_foreign_key :answer_tags, :tag_prompt_deployments if table_exists?(:tag_prompt_deployments)

    add_foreign_key :late_policies, :users, column: :instructor_id if table_exists?(:users)

    add_foreign_key :resubmission_times, :participants if table_exists?(:participants)

    add_foreign_key :review_bids, :participants if table_exists?(:participants)
    add_foreign_key :review_bids, :users if table_exists?(:users)
    add_foreign_key :review_bids, :assignments if table_exists?(:assignments)

    add_foreign_key :review_grades, :participants if table_exists?(:participants)

    add_foreign_key :review_comment_paste_bins, :review_grades if table_exists?(:review_grades)

    add_foreign_key :survey_deployments, :questionnaires if table_exists?(:questionnaires)

  end
end