SET FOREIGN_KEY_CHECKS = 0;
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `assignments_questionnaires`;
DROP TABLE IF EXISTS `automated_metareviews`;
DROP TABLE IF EXISTS `bids`;
DROP TABLE IF EXISTS `courses_users`;
DROP TABLE IF EXISTS `goldberg_content_pages`;
DROP TABLE IF EXISTS `goldberg_controller_actions`;
DROP TABLE IF EXISTS `goldberg_markup_styles`;
DROP TABLE IF EXISTS `goldberg_menu_items`;
DROP TABLE IF EXISTS `goldberg_permissions`;
DROP TABLE IF EXISTS `goldberg_roles`;
DROP TABLE IF EXISTS `goldberg_roles_permissions`;
DROP TABLE IF EXISTS `goldberg_site_controllers`;
DROP TABLE IF EXISTS `goldberg_system_settings`;
DROP TABLE IF EXISTS `goldberg_users`;
DROP TABLE IF EXISTS `mapping_strategies`;
DROP TABLE IF EXISTS `plugin_schema_info`;
DROP TABLE IF EXISTS `review_feedbacks`;
DROP TABLE IF EXISTS `review_mappings`;
DROP TABLE IF EXISTS `review_of_review_mappings`;
DROP TABLE IF EXISTS `review_of_review_scores`;
DROP TABLE IF EXISTS `review_of_reviews`;
DROP TABLE IF EXISTS `review_scores`;
DROP TABLE IF EXISTS `review_strategies`;
DROP TABLE IF EXISTS `reviews`;
DROP TABLE IF EXISTS `sessions`;
DROP TABLE IF EXISTS `survey_responses`;
DROP TABLE IF EXISTS `versions`;
DROP VIEW IF EXISTS `view1`;
CREATE TABLE IF NOT EXISTS `cakes` (
`id` BIGINT NOT NULL AUTO_INCREMENT,
`created_at` DATETIME NULL,
`updated_at` DATETIME NULL,
PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
ALTER TABLE `account_requests`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `email` varchar(255) NULL,
MODIFY COLUMN `full_name` varchar(255) NULL,
DROP COLUMN `fullname`,
MODIFY COLUMN `institution_id` BIGINT NULL,
MODIFY COLUMN `introduction` TEXT NULL,
DROP COLUMN `name`,
MODIFY COLUMN `role_id` BIGINT NULL,
DROP COLUMN `self_introduction`,
MODIFY COLUMN `status` varchar(255) NULL,
MODIFY COLUMN `updated_at` DATETIME NULL,
MODIFY COLUMN `username` varchar(255) NULL;
ALTER TABLE `answer_tags`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `answer_id` BIGINT NULL,
MODIFY COLUMN `confidence_level` DECIMAL(10,5) NULL,
MODIFY COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `tag_prompt_deployment_id` BIGINT NULL,
MODIFY COLUMN `updated_at` DATETIME NULL,
MODIFY COLUMN `user_id` BIGINT NULL,
MODIFY COLUMN `value` varchar(255) NULL;
ALTER TABLE `answers`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `answer` INT NULL,
MODIFY COLUMN `comments` TEXT NULL,
MODIFY COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `item_id` INT NULL DEFAULT 0,
MODIFY COLUMN `response_id` INT NULL,
MODIFY COLUMN `updated_at` DATETIME NULL;
ALTER TABLE `assignment_questionnaires`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `assignment_id` INT NULL,
MODIFY COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `dropdown` TINYINT(1) NULL,
MODIFY COLUMN `duty_id` BIGINT NULL,
MODIFY COLUMN `notification_threshold` INT NULL DEFAULT 15,
MODIFY COLUMN `questionnaire_id` INT NULL,
MODIFY COLUMN `questionnaire_weight` INT NULL,
MODIFY COLUMN `topic_id` BIGINT NULL,
MODIFY COLUMN `updated_at` DATETIME NULL,
MODIFY COLUMN `used_in_round` INT NULL,
DROP COLUMN `user_id`;
ALTER TABLE `assignments`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `URL` TEXT NULL,
MODIFY COLUMN `allow_selecting_additional_reviews_after_1st_round` TINYINT(1) NULL,
MODIFY COLUMN `allow_suggestions` TINYINT(1) NULL,
MODIFY COLUMN `auto_assign_mentor` TINYINT(1) NULL,
MODIFY COLUMN `available_to_students` TINYINT(1) NULL,
MODIFY COLUMN `bidding_for_reviews_enabled` TINYINT(1) NULL,
MODIFY COLUMN `calculate_penalty` TINYINT(1) NULL,
MODIFY COLUMN `can_bookmark_topics` TINYINT(1) NULL,
MODIFY COLUMN `can_choose_topic_to_review` TINYINT(1) NULL,
MODIFY COLUMN `can_review_same_topic` TINYINT(1) NULL,
MODIFY COLUMN `copy_flag` TINYINT(1) NULL,
MODIFY COLUMN `course_id` BIGINT NULL,
MODIFY COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `days_between_submissions` INT NULL,
MODIFY COLUMN `directory_path` varchar(255) NULL,
DROP COLUMN `duty_based_assignment?`,
MODIFY COLUMN `enable_pair_programming` TINYINT(1) NULL DEFAULT 0,
MODIFY COLUMN `has_teams` TINYINT(1) NULL DEFAULT 0,
MODIFY COLUMN `has_topics` TINYINT(1) NULL DEFAULT 0,
MODIFY COLUMN `instructor_grade_max_score` INT NULL,
MODIFY COLUMN `instructor_grade_min_score` INT NULL,
MODIFY COLUMN `instructor_id` BIGINT NULL,
MODIFY COLUMN `is_anonymous` TINYINT(1) NULL,
MODIFY COLUMN `is_answer_tagging_allowed` TINYINT(1) NULL,
MODIFY COLUMN `is_calibrated` TINYINT(1) NULL,
MODIFY COLUMN `is_coding_assignment` TINYINT(1) NULL,
MODIFY COLUMN `is_penalty_calculated` TINYINT(1) NULL,
MODIFY COLUMN `is_selfreview_enabled` TINYINT(1) NULL,
MODIFY COLUMN `late_policy_id` INT NULL,
MODIFY COLUMN `max_reviews_per_submission` INT NULL,
MODIFY COLUMN `max_team_size` INT NULL,
MODIFY COLUMN `microtask` TINYINT(1) NULL,
MODIFY COLUMN `name` varchar(255) NULL,
MODIFY COLUMN `num_metareviews_allowed` INT NULL,
MODIFY COLUMN `num_metareviews_required` INT NULL,
MODIFY COLUMN `num_quiz_questions` INT NULL,
MODIFY COLUMN `num_review_of_reviewers` INT NULL,
MODIFY COLUMN `num_review_of_reviews` INT NULL,
MODIFY COLUMN `num_reviewers` INT NULL,
MODIFY COLUMN `num_reviews` INT NULL,
MODIFY COLUMN `num_reviews_allowed` INT NULL,
MODIFY COLUMN `num_reviews_required` INT NULL,
MODIFY COLUMN `private` TINYINT(1) NULL,
DROP COLUMN `questionnaire_varies_by_duty`,
MODIFY COLUMN `require_quiz` TINYINT(1) NULL,
MODIFY COLUMN `review_assignment_strategy` varchar(255) NULL,
MODIFY COLUMN `review_topic_threshold` INT NULL,
MODIFY COLUMN `reviews_visible_to_all` TINYINT(1) NULL,
MODIFY COLUMN `rounds_of_reviews` INT NULL,
MODIFY COLUMN `sample_assignment_id` INT NULL,
MODIFY COLUMN `show_teammate_reviews` TINYINT(1) NULL,
MODIFY COLUMN `staggered_deadline` TINYINT(1) NULL,
MODIFY COLUMN `submitter_count` INT NULL,
MODIFY COLUMN `team_members_have_duty` TINYINT(1) NULL,
MODIFY COLUMN `team_reviewing_enabled` TINYINT(1) NULL,
MODIFY COLUMN `topics_assigned_by_bidding` TINYINT(1) NULL,
MODIFY COLUMN `updated_at` DATETIME NULL,
MODIFY COLUMN `vary_by_duty?` TINYINT(1) NULL,
MODIFY COLUMN `vary_by_round` TINYINT(1) NULL DEFAULT 0,
MODIFY COLUMN `vary_by_round?` TINYINT(1) NULL,
MODIFY COLUMN `vary_by_topic?` TINYINT(1) NULL;
ALTER TABLE `assignments_duties`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `assignment_id` BIGINT NULL,
MODIFY COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `duty_id` BIGINT NULL,
MODIFY COLUMN `updated_at` DATETIME NULL;
ALTER TABLE `bookmark_ratings`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `artifact_id` INT NULL,
MODIFY COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `rater_id` INT NULL,
MODIFY COLUMN `rating` INT NULL,
MODIFY COLUMN `updated_at` DATETIME NULL;
ALTER TABLE `bookmarks`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `description` TEXT NULL,
MODIFY COLUMN `title` TEXT NULL,
MODIFY COLUMN `topic_id` INT NULL,
MODIFY COLUMN `updated_at` DATETIME NULL,
MODIFY COLUMN `url` TEXT NULL,
MODIFY COLUMN `user_id` INT NULL;
ALTER TABLE `courses`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `directory_path` varchar(255) NULL,
MODIFY COLUMN `info` TEXT NULL,
MODIFY COLUMN `institution_id` BIGINT NULL,
MODIFY COLUMN `instructor_id` BIGINT NULL,
MODIFY COLUMN `is_private` TINYINT(1) NULL DEFAULT 0,
MODIFY COLUMN `language` TEXT NULL,
DROP COLUMN `locale`,
MODIFY COLUMN `name` varchar(255) NULL,
MODIFY COLUMN `updated_at` DATETIME NULL;
ALTER TABLE `deadline_rights`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `name` varchar(255) NULL;
ALTER TABLE `deadline_types`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `name` varchar(255) NULL;
ALTER TABLE `due_dates`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `assignment_id` BIGINT NULL,
ADD COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `deadline_name` varchar(255) NULL,
MODIFY COLUMN `deadline_type_id` INT NULL,
MODIFY COLUMN `delayed_job_id` varchar(255) NULL,
MODIFY COLUMN `description_url` varchar(255) NULL,
MODIFY COLUMN `due_at` DATETIME NULL,
MODIFY COLUMN `flag` TINYINT(1) NULL DEFAULT 0,
MODIFY COLUMN `parent_type` varchar(255) NULL,
MODIFY COLUMN `quiz_allowed_id` INT NULL DEFAULT 1,
ADD COLUMN `rereview_allowed_id` INT NULL,
ADD COLUMN `resubmission_allowed_id` INT NULL,
MODIFY COLUMN `review_allowed_id` INT NULL,
MODIFY COLUMN `review_of_review_allowed_id` INT NULL,
MODIFY COLUMN `round` INT NULL,
MODIFY COLUMN `submission_allowed_id` INT NULL,
MODIFY COLUMN `teammate_review_allowed_id` INT NULL DEFAULT 3,
MODIFY COLUMN `threshold` INT NULL DEFAULT 1,
MODIFY COLUMN `type` varchar(255) NULL,
ADD COLUMN `updated_at` DATETIME NULL;
ALTER TABLE `duties`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `assignment_id` BIGINT NULL,
MODIFY COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `instructor_id` BIGINT NULL,
MODIFY COLUMN `max_members_for_duty` INT NULL,
MODIFY COLUMN `name` varchar(255) NULL,
MODIFY COLUMN `private` TINYINT(1) NULL DEFAULT 0,
MODIFY COLUMN `updated_at` DATETIME NULL;
ALTER TABLE `institutions`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `name` varchar(255) NULL,
MODIFY COLUMN `updated_at` DATETIME NULL;
ALTER TABLE `invitations`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `assignment_id` INT NULL,
MODIFY COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `from_id` BIGINT NULL,
MODIFY COLUMN `reply_status` varchar(1) NULL,
MODIFY COLUMN `to_id` BIGINT NULL,
MODIFY COLUMN `updated_at` DATETIME NULL;
ALTER TABLE `items`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `alternatives` varchar(255) NULL,
MODIFY COLUMN `break_before` TINYINT(1) NULL,
MODIFY COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `max_label` varchar(255) NULL,
MODIFY COLUMN `min_label` varchar(255) NULL,
MODIFY COLUMN `question_type` varchar(255) NULL,
MODIFY COLUMN `questionnaire_id` BIGINT NULL,
MODIFY COLUMN `seq` DECIMAL(10,0) NULL,
MODIFY COLUMN `size` varchar(255) NULL,
MODIFY COLUMN `txt` TEXT NULL,
MODIFY COLUMN `type` TEXT NULL,
MODIFY COLUMN `updated_at` DATETIME NULL,
MODIFY COLUMN `weight` INT NULL;
ALTER TABLE `join_team_requests`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `comments` TEXT NULL,
MODIFY COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `participant_id` INT NULL,
MODIFY COLUMN `reply_status` varchar(255) NULL,
MODIFY COLUMN `status` TEXT NULL,
MODIFY COLUMN `team_id` INT NULL,
MODIFY COLUMN `updated_at` DATETIME NULL;
ALTER TABLE `languages`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `name` varchar(255) NULL;
ALTER TABLE `late_policies`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `instructor_id` BIGINT NULL,
MODIFY COLUMN `max_penalty` INT NULL DEFAULT 0,
MODIFY COLUMN `penalty_per_unit` FLOAT NULL,
MODIFY COLUMN `penalty_unit` varchar(255) NULL,
MODIFY COLUMN `policy_name` varchar(255) NULL,
MODIFY COLUMN `private` TINYINT(1) NULL DEFAULT 1,
MODIFY COLUMN `times_used` INT NULL DEFAULT 0;
ALTER TABLE `nodes`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `node_object_id` INT NULL,
MODIFY COLUMN `parent_id` INT NULL,
MODIFY COLUMN `type` varchar(255) NULL,
MODIFY COLUMN `updated_at` DATETIME NULL;
ALTER TABLE `participants`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
DROP COLUMN `Hamer`,
DROP COLUMN `Lauw`,
MODIFY COLUMN `OK_to_show` TINYINT(1) NULL DEFAULT 0,
MODIFY COLUMN `authorization` varchar(255) NULL,
MODIFY COLUMN `can_mentor` TINYINT(1) NULL,
MODIFY COLUMN `can_review` TINYINT(1) NULL DEFAULT 1,
MODIFY COLUMN `can_submit` TINYINT(1) NULL DEFAULT 1,
MODIFY COLUMN `can_take_quiz` TINYINT(1) NULL,
MODIFY COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `current_stage` varchar(255) NULL,
MODIFY COLUMN `duty_id` INT NULL,
MODIFY COLUMN `grade` FLOAT NULL,
MODIFY COLUMN `handle` varchar(255) NULL,
MODIFY COLUMN `join_team_request_id` BIGINT NULL,
MODIFY COLUMN `parent_id` INT NULL,
MODIFY COLUMN `stage_deadline` DATETIME NULL,
MODIFY COLUMN `team_id` BIGINT NULL,
MODIFY COLUMN `topic` varchar(255) NULL,
MODIFY COLUMN `type` varchar(255) NULL,
MODIFY COLUMN `updated_at` DATETIME NULL,
MODIFY COLUMN `user_id` BIGINT NULL;
ALTER TABLE `password_resets`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `token` varchar(255) NULL,
MODIFY COLUMN `updated_at` DATETIME NULL,
MODIFY COLUMN `user_email` varchar(255) NULL;
ALTER TABLE `permissions`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `name` varchar(255) NULL;
ALTER TABLE `project_topics`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `assignment_id` BIGINT NULL,
MODIFY COLUMN `category` TEXT NULL,
ADD COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `description` TEXT NULL,
MODIFY COLUMN `link` varchar(255) NULL,
MODIFY COLUMN `max_choosers` INT NULL DEFAULT 0,
MODIFY COLUMN `micropayment` INT NULL DEFAULT 0,
MODIFY COLUMN `private_to` INT NULL,
MODIFY COLUMN `topic_identifier` varchar(10) NULL,
MODIFY COLUMN `topic_name` TEXT NULL,
ADD COLUMN `updated_at` DATETIME NULL;
ALTER TABLE `question_advice`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `advice` TEXT NULL,
ADD COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `question_id` BIGINT NULL,
MODIFY COLUMN `score` INT NULL,
ADD COLUMN `updated_at` DATETIME NULL;
ALTER TABLE `question_types`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
ADD COLUMN `created_at` DATETIME NULL,
ADD COLUMN `name` varchar(255) NULL,
MODIFY COLUMN `type` TEXT NULL,
ADD COLUMN `updated_at` DATETIME NULL;
ALTER TABLE `questionnaire_types`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
ADD COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `name` varchar(255) NULL,
ADD COLUMN `updated_at` DATETIME NULL;
ALTER TABLE `questionnaires`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `display_type` varchar(255) NULL,
MODIFY COLUMN `instruction_loc` TEXT NULL,
MODIFY COLUMN `instructor_id` INT NULL,
MODIFY COLUMN `max_question_score` INT NULL,
MODIFY COLUMN `min_question_score` INT NULL,
MODIFY COLUMN `name` varchar(255) NULL,
MODIFY COLUMN `private` TINYINT(1) NULL,
MODIFY COLUMN `questionnaire_type` varchar(255) NULL,
MODIFY COLUMN `type` TEXT NULL,
MODIFY COLUMN `updated_at` DATETIME NULL;
ALTER TABLE `quiz_question_choices`
MODIFY COLUMN `id` INTEGER NOT NULL AUTO_INCREMENT,
ADD COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `is_correct` TINYINT(1) NULL DEFAULT 0,
MODIFY COLUMN `question_id` INT NULL,
MODIFY COLUMN `txt` TEXT NULL,
ADD COLUMN `updated_at` DATETIME NULL;
ALTER TABLE `response_maps`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
DROP COLUMN `calibrate_to`,
MODIFY COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `for_calibration` TINYINT(1) NULL,
MODIFY COLUMN `reviewed_object_id` INT NULL DEFAULT 0,
MODIFY COLUMN `reviewee_id` INT NULL DEFAULT 0,
MODIFY COLUMN `reviewer_id` INT NULL DEFAULT 0,
DROP COLUMN `team_reviewing_enabled`,
MODIFY COLUMN `type` varchar(255) NULL,
MODIFY COLUMN `updated_at` DATETIME NULL;
ALTER TABLE `responses`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `additional_comment` TEXT NULL,
MODIFY COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `is_submitted` TINYINT(1) NULL DEFAULT 0,
MODIFY COLUMN `response_map_id` INT NULL DEFAULT 0,
MODIFY COLUMN `round` INT NULL,
MODIFY COLUMN `updated_at` DATETIME NULL,
MODIFY COLUMN `version_num` INT NULL,
MODIFY COLUMN `visibility` TEXT NULL;
ALTER TABLE `resubmission_times`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `participant_id` BIGINT NULL,
MODIFY COLUMN `resubmitted_at` DATETIME NULL;
ALTER TABLE `review_bids`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `assignment_id` BIGINT NULL,
MODIFY COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `participant_id` BIGINT NULL,
MODIFY COLUMN `priority` INT NULL,
MODIFY COLUMN `project_topic_id` BIGINT NULL,
MODIFY COLUMN `updated_at` DATETIME NULL,
MODIFY COLUMN `user_id` BIGINT NULL;
ALTER TABLE `review_comment_paste_bins`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `review_comment` TEXT NULL,
MODIFY COLUMN `review_grade_id` BIGINT NULL,
MODIFY COLUMN `title` varchar(255) NULL,
MODIFY COLUMN `updated_at` DATETIME NULL;
ALTER TABLE `review_grades`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `comment_for_reviewer` TEXT NULL,
MODIFY COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `grade_for_reviewer` FLOAT NULL,
MODIFY COLUMN `grader_id` INT NULL,
MODIFY COLUMN `participant_id` BIGINT NULL,
MODIFY COLUMN `updated_at` DATETIME NULL;
ALTER TABLE `roles`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `default_page_id` INT NULL,
MODIFY COLUMN `description` TEXT NULL,
MODIFY COLUMN `name` varchar(255) NULL,
MODIFY COLUMN `parent_id` BIGINT NULL,
MODIFY COLUMN `updated_at` DATETIME NULL;
ALTER TABLE `roles_permissions`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `permission_id` INT NULL,
MODIFY COLUMN `role_id` INT NULL;
ALTER TABLE `sample_reviews`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `assignment_id` INT NULL,
MODIFY COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `response_id` INT NULL,
MODIFY COLUMN `updated_at` DATETIME NULL;
ALTER TABLE `signed_up_teams`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `advertise_for_partner` TINYINT(1) NULL,
MODIFY COLUMN `comments_for_advertisement` TEXT NULL,
MODIFY COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `is_waitlisted` TINYINT(1) NULL,
MODIFY COLUMN `preference_priority_number` INT NULL,
MODIFY COLUMN `project_topic_id` BIGINT NULL,
MODIFY COLUMN `team_id` BIGINT NULL,
MODIFY COLUMN `updated_at` DATETIME NULL;
ALTER TABLE `submission_records`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `content` TEXT NULL,
MODIFY COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `operation` varchar(255) NULL,
MODIFY COLUMN `record_type` TEXT NULL,
MODIFY COLUMN `submitted_by` varchar(255) NULL,
MODIFY COLUMN `team_id` INT NULL,
MODIFY COLUMN `updated_at` DATETIME NULL;
ALTER TABLE `suggestion_comments`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `commenter` varchar(255) NULL,
MODIFY COLUMN `comments` TEXT NULL,
MODIFY COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `suggestion_id` INT NULL,
MODIFY COLUMN `updated_at` DATETIME NULL,
MODIFY COLUMN `visible_to_student` TINYINT(1) NULL DEFAULT 0,
MODIFY COLUMN `vote` varchar(255) NULL;
ALTER TABLE `suggestions`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `assignment_id` INT NULL,
MODIFY COLUMN `description` TEXT NULL,
MODIFY COLUMN `signup_preference` varchar(255) NULL,
MODIFY COLUMN `status` varchar(255) NULL,
MODIFY COLUMN `title` varchar(255) NULL,
MODIFY COLUMN `username` varchar(255) NULL;
ALTER TABLE `survey_deployments`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
ADD COLUMN `deployment_type` varchar(255) NULL,
MODIFY COLUMN `end_date` DATETIME NULL,
MODIFY COLUMN `global_survey_id` INT NULL,
MODIFY COLUMN `last_reminder` DATETIME NULL,
MODIFY COLUMN `parent_id` INT NULL DEFAULT 0,
MODIFY COLUMN `questionnaire_id` BIGINT NULL,
MODIFY COLUMN `start_date` DATETIME NULL,
MODIFY COLUMN `type` TEXT NULL;
ALTER TABLE `ta_mappings`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `course_id` BIGINT NULL,
ADD COLUMN `created_at` DATETIME NULL,
DROP COLUMN `ta_id`,
ADD COLUMN `updated_at` DATETIME NULL,
MODIFY COLUMN `user_id` BIGINT NULL;
ALTER TABLE `tag_prompt_deployments`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `answer_length_threshold` INT NULL,
MODIFY COLUMN `assignment_id` BIGINT NULL,
MODIFY COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `question_type` varchar(255) NULL,
MODIFY COLUMN `questionnaire_id` BIGINT NULL,
MODIFY COLUMN `tag_prompt_id` BIGINT NULL,
MODIFY COLUMN `updated_at` DATETIME NULL;
ALTER TABLE `tag_prompts`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `control_type` varchar(255) NULL,
MODIFY COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `desc` varchar(255) NULL,
MODIFY COLUMN `prompt` varchar(255) NULL,
MODIFY COLUMN `updated_at` DATETIME NULL;
ALTER TABLE `teams`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
DROP COLUMN `advertise_for_partner`,
MODIFY COLUMN `comment_for_submission` TEXT NULL,
DROP COLUMN `comments_for_advertisement`,
MODIFY COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `directory_num` INT NULL,
MODIFY COLUMN `grade_for_submission` INT NULL,
DROP COLUMN `make_public`,
MODIFY COLUMN `name` varchar(255) NULL,
DROP COLUMN `pair_programming_request`,
MODIFY COLUMN `parent_id` INT NULL,
MODIFY COLUMN `submitted_hyperlinks` TEXT NULL,
MODIFY COLUMN `type` varchar(255) NULL,
MODIFY COLUMN `updated_at` DATETIME NULL;
ALTER TABLE `teams_participants`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `duty_id` INT NULL,
DROP COLUMN `pair_programming_status`,
MODIFY COLUMN `participant_id` BIGINT NULL,
MODIFY COLUMN `team_id` BIGINT NULL,
MODIFY COLUMN `updated_at` DATETIME NULL,
MODIFY COLUMN `user_id` INT NULL;
ALTER TABLE `teams_users`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `team_id` BIGINT NULL,
MODIFY COLUMN `updated_at` DATETIME NULL,
MODIFY COLUMN `user_id` BIGINT NULL;
ALTER TABLE `topic_bids`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `priority` INT NULL,
MODIFY COLUMN `team_id` INT NULL,
MODIFY COLUMN `topic_id` INT NULL,
MODIFY COLUMN `updated_at` DATETIME NULL;
ALTER TABLE `track_notifications`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `notification_id` INT NULL,
MODIFY COLUMN `updated_at` DATETIME NULL,
MODIFY COLUMN `user_id` INT NULL;
ALTER TABLE `tree_folders`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `child_type` varchar(255) NULL,
MODIFY COLUMN `name` varchar(255) NULL,
MODIFY COLUMN `parent_id` INT NULL;
ALTER TABLE `user_pastebins`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `created_at` DATETIME NULL,
MODIFY COLUMN `long_form` TEXT NULL,
MODIFY COLUMN `short_form` varchar(255) NULL,
MODIFY COLUMN `updated_at` DATETIME NULL,
MODIFY COLUMN `user_id` INT NULL;
ALTER TABLE `users`
MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT,
MODIFY COLUMN `copy_of_emails` TINYINT(1) NULL DEFAULT 0,
MODIFY COLUMN `created_at` DATETIME NULL,
DROP COLUMN `crypted_password`,
MODIFY COLUMN `email` varchar(255) NULL,
MODIFY COLUMN `email_on_review` TINYINT(1) NULL DEFAULT 0,
MODIFY COLUMN `email_on_submission` TINYINT(1) NULL DEFAULT 0,
MODIFY COLUMN `etc_icons_on_homepage` TINYINT(1) NULL DEFAULT 0,
MODIFY COLUMN `handle` varchar(255) NULL,
MODIFY COLUMN `institution_id` BIGINT NULL,
MODIFY COLUMN `is_new_user` TINYINT(1) NULL DEFAULT 1,
MODIFY COLUMN `locale` INT NULL,
MODIFY COLUMN `mru_directory_path` varchar(255) NULL,
MODIFY COLUMN `name` varchar(255) NULL,
MODIFY COLUMN `parent_id` BIGINT NULL,
MODIFY COLUMN `password_digest` varchar(255) NULL,
MODIFY COLUMN `password_salt` TEXT NULL,
MODIFY COLUMN `private_by_default` TINYINT(1) NULL,
MODIFY COLUMN `public_key` TEXT NULL,
MODIFY COLUMN `role_id` BIGINT NULL,
MODIFY COLUMN `time_zone_pref` varchar(255) NULL,
MODIFY COLUMN `updated_at` DATETIME NULL,
MODIFY COLUMN `username` varchar(255) NULL;
ALTER TABLE `account_requests` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `answer_tags` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `answers` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `assignment_questionnaires` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `assignments` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `bookmark_ratings` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `bookmarks` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `courses` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `deadline_rights` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `deadline_types` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `due_dates` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `duties` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `institutions` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `invitations` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `items` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `join_team_requests` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `languages` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `late_policies` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `nodes` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `participants` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `password_resets` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `permissions` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `project_topics` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `question_advice` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `question_types` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `questionnaire_types` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `questionnaires` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `quiz_question_choices` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `response_maps` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `responses` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `resubmission_times` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `review_bids` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `review_comment_paste_bins` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `review_grades` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `roles` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `roles_permissions` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `sample_reviews` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `signed_up_teams` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `submission_records` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `suggestion_comments` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `suggestions` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `survey_deployments` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `ta_mappings` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `tag_prompt_deployments` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `tag_prompts` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `teams` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `teams_participants` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `track_notifications` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `tree_folders` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `user_pastebins` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE `users` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
UPDATE `signed_up_teams` SET project_topic_id = NULL WHERE project_topic_id = 0;
UPDATE `signed_up_teams` SET team_id = NULL WHERE team_id = 0;
UPDATE `questionnaires` SET min_question_score = 0 WHERE min_question_score IS NOT NULL AND min_question_score < 0;
UPDATE `questionnaires` SET max_question_score = 0 WHERE max_question_score IS NOT NULL AND max_question_score < 0;
ALTER TABLE `account_requests` ADD CONSTRAINT `fk_canon_account_requests_institution_id` FOREIGN KEY (`institution_id`) REFERENCES `institutions` (`id`);
ALTER TABLE `account_requests` ADD CONSTRAINT `fk_canon_account_requests_role_id` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`);
ALTER TABLE `answer_tags` ADD CONSTRAINT `fk_canon_answer_tags_answer_id` FOREIGN KEY (`answer_id`) REFERENCES `answers` (`id`);
ALTER TABLE `answer_tags` ADD CONSTRAINT `fk_canon_answer_tags_tag_prompt_deployment_id` FOREIGN KEY (`tag_prompt_deployment_id`) REFERENCES `tag_prompt_deployments` (`id`);
ALTER TABLE `answer_tags` ADD CONSTRAINT `fk_canon_answer_tags_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);
ALTER TABLE `assignments` ADD CONSTRAINT `fk_canon_assignments_course_id` FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`);
ALTER TABLE `assignments` ADD CONSTRAINT `fk_canon_assignments_instructor_id` FOREIGN KEY (`instructor_id`) REFERENCES `users` (`id`);
ALTER TABLE `assignments_duties` ADD CONSTRAINT `fk_canon_assignments_duties_assignment_id` FOREIGN KEY (`assignment_id`) REFERENCES `assignments` (`id`);
ALTER TABLE `courses` ADD CONSTRAINT `fk_canon_courses_institution_id` FOREIGN KEY (`institution_id`) REFERENCES `institutions` (`id`);
ALTER TABLE `courses` ADD CONSTRAINT `fk_canon_courses_instructor_id` FOREIGN KEY (`instructor_id`) REFERENCES `users` (`id`);
ALTER TABLE `duties` ADD CONSTRAINT `fk_canon_duties_instructor_id` FOREIGN KEY (`instructor_id`) REFERENCES `users` (`id`);
ALTER TABLE `invitations` ADD CONSTRAINT `fk_canon_invitations_from_id` FOREIGN KEY (`from_id`) REFERENCES `participants` (`id`);
ALTER TABLE `invitations` ADD CONSTRAINT `fk_canon_invitations_to_id` FOREIGN KEY (`to_id`) REFERENCES `participants` (`id`);
ALTER TABLE `items` ADD CONSTRAINT `fk_canon_items_questionnaire_id` FOREIGN KEY (`questionnaire_id`) REFERENCES `questionnaires` (`id`);
ALTER TABLE `late_policies` ADD CONSTRAINT `fk_canon_late_policies_instructor_id` FOREIGN KEY (`instructor_id`) REFERENCES `users` (`id`);
ALTER TABLE `participants` ADD CONSTRAINT `fk_canon_participants_join_team_request_id` FOREIGN KEY (`join_team_request_id`) REFERENCES `join_team_requests` (`id`);
ALTER TABLE `participants` ADD CONSTRAINT `fk_canon_participants_team_id` FOREIGN KEY (`team_id`) REFERENCES `teams` (`id`);
ALTER TABLE `participants` ADD CONSTRAINT `fk_canon_participants_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);
ALTER TABLE `project_topics` ADD CONSTRAINT `fk_canon_project_topics_assignment_id` FOREIGN KEY (`assignment_id`) REFERENCES `assignments` (`id`);
ALTER TABLE `question_advice` ADD CONSTRAINT `fk_canon_question_advice_question_id` FOREIGN KEY (`question_id`) REFERENCES `items` (`id`);
ALTER TABLE `resubmission_times` ADD CONSTRAINT `fk_canon_resubmission_times_participant_id` FOREIGN KEY (`participant_id`) REFERENCES `participants` (`id`);
ALTER TABLE `review_bids` ADD CONSTRAINT `fk_canon_review_bids_assignment_id` FOREIGN KEY (`assignment_id`) REFERENCES `assignments` (`id`);
ALTER TABLE `review_bids` ADD CONSTRAINT `fk_canon_review_bids_participant_id` FOREIGN KEY (`participant_id`) REFERENCES `participants` (`id`);
ALTER TABLE `review_bids` ADD CONSTRAINT `fk_canon_review_bids_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);
ALTER TABLE `review_comment_paste_bins` ADD CONSTRAINT `fk_canon_review_comment_paste_bins_review_grade_id` FOREIGN KEY (`review_grade_id`) REFERENCES `review_grades` (`id`);
ALTER TABLE `review_grades` ADD CONSTRAINT `fk_canon_review_grades_participant_id` FOREIGN KEY (`participant_id`) REFERENCES `participants` (`id`);
ALTER TABLE `roles` ADD CONSTRAINT `fk_canon_roles_parent_id` FOREIGN KEY (`parent_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE;
ALTER TABLE `signed_up_teams` ADD CONSTRAINT `fk_canon_signed_up_teams_project_topic_id` FOREIGN KEY (`project_topic_id`) REFERENCES `project_topics` (`id`);
ALTER TABLE `signed_up_teams` ADD CONSTRAINT `fk_canon_signed_up_teams_team_id` FOREIGN KEY (`team_id`) REFERENCES `teams` (`id`);
ALTER TABLE `survey_deployments` ADD CONSTRAINT `fk_canon_survey_deployments_questionnaire_id` FOREIGN KEY (`questionnaire_id`) REFERENCES `questionnaires` (`id`);
ALTER TABLE `ta_mappings` ADD CONSTRAINT `fk_canon_ta_mappings_course_id` FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`);
ALTER TABLE `ta_mappings` ADD CONSTRAINT `fk_canon_ta_mappings_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);
ALTER TABLE `tag_prompt_deployments` ADD CONSTRAINT `fk_canon_tag_prompt_deployments_assignment_id` FOREIGN KEY (`assignment_id`) REFERENCES `assignments` (`id`);
ALTER TABLE `tag_prompt_deployments` ADD CONSTRAINT `fk_canon_tag_prompt_deployments_questionnaire_id` FOREIGN KEY (`questionnaire_id`) REFERENCES `questionnaires` (`id`);
ALTER TABLE `tag_prompt_deployments` ADD CONSTRAINT `fk_canon_tag_prompt_deployments_tag_prompt_id` FOREIGN KEY (`tag_prompt_id`) REFERENCES `tag_prompts` (`id`);
ALTER TABLE `teams_participants` ADD CONSTRAINT `fk_canon_teams_participants_participant_id` FOREIGN KEY (`participant_id`) REFERENCES `participants` (`id`);
ALTER TABLE `teams_participants` ADD CONSTRAINT `fk_canon_teams_participants_team_id` FOREIGN KEY (`team_id`) REFERENCES `teams` (`id`);
ALTER TABLE `teams_users` ADD CONSTRAINT `fk_canon_teams_users_team_id` FOREIGN KEY (`team_id`) REFERENCES `teams` (`id`);
ALTER TABLE `teams_users` ADD CONSTRAINT `fk_canon_teams_users_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);
ALTER TABLE `users` ADD CONSTRAINT `fk_canon_users_institution_id` FOREIGN KEY (`institution_id`) REFERENCES `institutions` (`id`);
ALTER TABLE `users` ADD CONSTRAINT `fk_canon_users_role_id` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`);
ALTER TABLE `users` ADD CONSTRAINT `fk_canon_users_parent_id` FOREIGN KEY (`parent_id`) REFERENCES `users` (`id`);
DROP VIEW IF EXISTS `score_views`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `score_views` AS
SELECT ques.`weight` AS `question_weight`,
       ques.`type` AS `type`,
       q1.`id` AS `q1_id`,
       q1.`name` AS `q1_name`,
       q1.`instructor_id` AS `q1_instructor_id`,
       q1.`private` AS `q1_private`,
       q1.`min_question_score` AS `q1_min_question_score`,
       q1.`max_question_score` AS `q1_max_question_score`,
       q1.`created_at` AS `q1_created_at`,
       q1.`updated_at` AS `q1_updated_at`,
       q1.`type` AS `q1_type`,
       q1.`display_type` AS `q1_display_type`,
       ques.`id` AS `ques_id`,
       ques.`questionnaire_id` AS `ques_questionnaire_id`,
       s.`id` AS `s_id`,
       s.`item_id` AS `s_question_id`,
       s.`answer` AS `s_score`,
       s.`comments` AS `s_comments`,
       s.`response_id` AS `s_response_id`
FROM ((`items` `ques` LEFT JOIN `questionnaires` `q1` ON ((`ques`.`questionnaire_id` = `q1`.`id`)))
      LEFT JOIN `answers` `s` ON ((`ques`.`id` = `s`.`item_id`)));
SET FOREIGN_KEY_CHECKS = 1;
SET FOREIGN_KEY_CHECKS = 1;
