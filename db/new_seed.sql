CREATE DATABASE IF NOT EXISTS reimplementation;
USE reimplementation;
SET FOREIGN_KEY_CHECKS = 0;
DELIMITER $$

CREATE TABLE IF NOT EXISTS `tag_prompts` (
  `id` int NOT NULL AUTO_INCREMENT,
  `prompt` varchar(255) DEFAULT NULL,
  `desc` varchar(255) DEFAULT NULL,
  `control_type` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
);


CREATE TABLE IF NOT EXISTS `tag_prompt_deployments` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tag_prompt_id` int DEFAULT NULL,
  `assignment_id` bigint DEFAULT NULL,
  `questionnaire_id` bigint DEFAULT NULL,
  `question_type` varchar(255) DEFAULT NULL,
  `answer_length_threshold` int DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_tag_prompt_deployments_on_tag_prompt_id` (`tag_prompt_id`),
  KEY `index_tag_prompt_deployments_on_assignment_id` (`assignment_id`),
  KEY `index_tag_prompt_deployments_on_questionnaire_id` (`questionnaire_id`),
  CONSTRAINT `fk_rails_7a44de7225` FOREIGN KEY (`assignment_id`) REFERENCES `assignments` (`id`),
  CONSTRAINT `fk_rails_c3b5a3cf6f` FOREIGN KEY (`questionnaire_id`) REFERENCES `questionnaires` (`id`),
  CONSTRAINT `fk_rails_fbf75bc17c` FOREIGN KEY (`tag_prompt_id`) REFERENCES `tag_prompts` (`id`)
);


CREATE TABLE IF NOT EXISTS `answer_tags` (
  `id` int NOT NULL AUTO_INCREMENT,
  `answer_id` bigint DEFAULT NULL,
  `tag_prompt_deployment_id` int DEFAULT NULL,
  `user_id` bigint DEFAULT NULL,
  `value` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `confidence_level` decimal(10,5) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_answer_tags_on_answer_id` (`answer_id`),
  KEY `index_answer_tags_on_tag_prompt_deployment_id` (`tag_prompt_deployment_id`),
  KEY `index_answer_tags_on_user_id` (`user_id`),
  CONSTRAINT `fk_rails_36ff09eab9` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_rails_6c5d47c4e2` FOREIGN KEY (`answer_id`) REFERENCES `answers` (`id`),
  CONSTRAINT `fk_rails_ec0fee5d79` FOREIGN KEY (`tag_prompt_deployment_id`) REFERENCES `tag_prompt_deployments` (`id`)
);


CREATE TABLE IF NOT EXISTS `bids` (
  `id` int NOT NULL AUTO_INCREMENT,
  `topic_id` int DEFAULT NULL,
  `team_id` int DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `priority` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_bids_on_topic_id` (`topic_id`),
  KEY `index_bids_on_team_id` (`team_id`)
);

CREATE TABLE IF NOT EXISTS `deadline_rights` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `deadline_types` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `languages` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `markup_styles` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `password_resets` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_email` varchar(255) DEFAULT NULL,
  `token` varchar(255) DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `permissions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
);


CREATE TABLE IF NOT EXISTS `sample_reviews` (
  `id` int NOT NULL AUTO_INCREMENT,
  `assignment_id` int DEFAULT NULL,
  `response_id` int DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `submission_records` (
  `id` int NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `type` text,
  `content` varchar(255) DEFAULT NULL,
  `operation` varchar(255) DEFAULT NULL,
  `team_id` int DEFAULT NULL,
  `user` varchar(255) DEFAULT NULL,
  `assignment_id` int DEFAULT NULL,
  PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `suggestion_comments` (
  `id` int NOT NULL AUTO_INCREMENT,
  `comments` text,
  `commenter` varchar(255) DEFAULT NULL,
  `vote` varchar(255) DEFAULT NULL,
  `suggestion_id` int DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `visible_to_student` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `suggestions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `assignment_id` int DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `description` text,
  `status` varchar(255) DEFAULT NULL,
  `unityID` varchar(255) DEFAULT NULL,
  `signup_preference` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `tree_folders` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `child_type` varchar(255) DEFAULT NULL,
  `parent_id` int DEFAULT NULL,
  PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `user_pastebins` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `short_form` varchar(255) DEFAULT NULL,
  `long_form` text,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
);
CREATE TABLE IF NOT EXISTS `automated_metareviews` (
  `id` int NOT NULL AUTO_INCREMENT,
  `relevance` float DEFAULT NULL,
  `content_summative` float DEFAULT NULL,
  `content_problem` float DEFAULT NULL,
  `content_advisory` float DEFAULT NULL,
  `tone_positive` float DEFAULT NULL,
  `tone_negative` float DEFAULT NULL,
  `tone_neutral` float DEFAULT NULL,
  `quantity` int DEFAULT NULL,
  `plagiarism` int DEFAULT NULL,
  `version_num` int DEFAULT NULL,
  `response_id` bigint DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_automated_metareviews_responses_id` (`response_id`),
  CONSTRAINT `fk_automated_metareviews_responses_id` FOREIGN KEY (`response_id`) REFERENCES `responses` (`id`)
);

CREATE TABLE IF NOT EXISTS `duties` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `max_members_for_duty` int DEFAULT NULL,
  `assignment_id` bigint DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_duties_on_assignment_id` (`assignment_id`),
  CONSTRAINT `fk_rails_3418df616a` FOREIGN KEY (`assignment_id`) REFERENCES `assignments` (`id`)
);

CREATE TABLE IF NOT EXISTS `late_policies` (
  `id` int NOT NULL AUTO_INCREMENT,
  `penalty_per_unit` float DEFAULT NULL,
  `max_penalty` int NOT NULL DEFAULT '0',
  `penalty_unit` varchar(255) NOT NULL,
  `times_used` int NOT NULL DEFAULT '0',
  `instructor_id` bigint NOT NULL,
  `policy_name` varchar(255) NOT NULL,
  `private` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `fk_instructor_id` (`instructor_id`),
  CONSTRAINT `fk_instructor_id` FOREIGN KEY (`instructor_id`) REFERENCES `users` (`id`)
);


CREATE TABLE IF NOT EXISTS `notifications` (
  `id` int NOT NULL AUTO_INCREMENT,
  `subject` varchar(255) DEFAULT NULL,
  `description` text,
  `expiration_date` date DEFAULT NULL,
  `active_flag` tinyint(1) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `course_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_notifications_on_course_id` (`course_id`)
);

CREATE TABLE IF NOT EXISTS `resubmission_times` (
  `id` int NOT NULL AUTO_INCREMENT,
  `participant_id` bigint DEFAULT NULL,
  `resubmitted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_resubmission_times_participants` (`participant_id`),
  CONSTRAINT `fk_resubmission_times_participants` FOREIGN KEY (`participant_id`) REFERENCES `participants` (`id`)
);

CREATE TABLE IF NOT EXISTS `review_bids` (
  `id` int NOT NULL AUTO_INCREMENT,
  `priority` int DEFAULT NULL,
  `signuptopic_id` bigint DEFAULT NULL,
  `participant_id` bigint DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `user_id` bigint DEFAULT NULL,
  `assignment_id` bigint DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_rails_549e23ae08` (`assignment_id`) USING BTREE,
  KEY `fk_rails_ab93feeb35` (`participant_id`) USING BTREE,
  KEY `fk_rails_e88fa4058f` (`signuptopic_id`) USING BTREE,
  KEY `fk_rails_6041e1cdb9` (`user_id`) USING BTREE,
  CONSTRAINT `fk_rails_05b6922602` FOREIGN KEY (`signuptopic_id`) REFERENCES `sign_up_topics` (`id`),
  CONSTRAINT `fk_rails_549e23ae08` FOREIGN KEY (`assignment_id`) REFERENCES `assignments` (`id`),
  CONSTRAINT `fk_rails_6041e1cdb9` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_rails_ab93feeb35` FOREIGN KEY (`participant_id`) REFERENCES `participants` (`id`)
);

CREATE TABLE IF NOT EXISTS `review_grades` (
  `id` int NOT NULL AUTO_INCREMENT,
  `participant_id` bigint DEFAULT NULL,
  `grade_for_reviewer` int DEFAULT NULL,
  `comment_for_reviewer` text,
  `review_graded_at` datetime DEFAULT NULL,
  `reviewer_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_rails_29587cf6a9` (`participant_id`),
  CONSTRAINT `fk_rails_29587cf6a9` FOREIGN KEY (`participant_id`) REFERENCES `participants` (`id`)
);
CREATE TABLE IF NOT EXISTS `review_comment_paste_bins` (
  `id` int NOT NULL AUTO_INCREMENT,
  `review_grade_id` int DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `review_comment` mediumtext,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_rails_0a539bcc81` (`review_grade_id`),
  CONSTRAINT `fk_rails_0a539bcc81` FOREIGN KEY (`review_grade_id`) REFERENCES `review_grades` (`id`)
);

CREATE TABLE IF NOT EXISTS `roles_permissions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `role_id` int NOT NULL DEFAULT '0',
  `permission_id` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `fk_roles_permission_role_id` (`role_id`),
  KEY `fk_roles_permission_permission_id` (`permission_id`)
);



CREATE TABLE IF NOT EXISTS `survey_deployments` (
  `id` int NOT NULL AUTO_INCREMENT,
  `questionnaire_id` bigint DEFAULT NULL,
  `start_date` datetime DEFAULT NULL,
  `end_date` datetime DEFAULT NULL,
  `last_reminder` datetime DEFAULT NULL,
  `parent_id` int NOT NULL DEFAULT '0',
  `global_survey_id` int DEFAULT NULL,
  `type` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_rails_7c62b6ef2b` (`questionnaire_id`),
  CONSTRAINT `fk_rails_7c62b6ef2b` FOREIGN KEY (`questionnaire_id`) REFERENCES `questionnaires` (`id`)
);


CREATE TABLE IF NOT EXISTS `track_notifications` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `notification_id` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  KEY `notification_id` (`notification_id`)
);





DROP PROCEDURE IF EXISTS rename_if_exists $$
CREATE PROCEDURE rename_if_exists(
  IN tbl VARCHAR(255),
  IN old_col VARCHAR(255),
  IN new_col VARCHAR(255),
  IN new_type VARCHAR(255)
)
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = tbl
      AND column_name = old_col
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = tbl
      AND column_name = new_col
  ) THEN
    SET @sql = CONCAT(
      'ALTER TABLE `', tbl,
      '` CHANGE COLUMN `', old_col, '` `', new_col, '` ', new_type
    );
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END $$

DROP PROCEDURE IF EXISTS drop_column_if_exists $$
CREATE PROCEDURE drop_column_if_exists(
  IN tbl VARCHAR(255),
  IN col VARCHAR(255)
)
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = tbl
      AND column_name = col
  ) THEN
    SET @sql = CONCAT(
      'ALTER TABLE `', tbl,
      '` DROP COLUMN `', col, '`'
    );
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END $$

DROP PROCEDURE IF EXISTS drop_questionnaires_display_type $$
CREATE PROCEDURE drop_questionnaires_display_type()
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'questionnaires'
      AND column_name = 'display_type'
  ) THEN
    SET @old_sql_mode = @@sql_mode;
    SET @new_sql_mode =
      REPLACE(REPLACE(@old_sql_mode,'NO_ZERO_DATE',''),'NO_ZERO_IN_DATE','');
    SET SESSION sql_mode = @new_sql_mode;

    SET @sql = 'ALTER TABLE `questionnaires` DROP COLUMN `display_type`';
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SET SESSION sql_mode = @old_sql_mode;
  END IF;
END $$

DROP PROCEDURE IF EXISTS add_column_if_not_exists $$
CREATE PROCEDURE add_column_if_not_exists(
  IN tbl VARCHAR(255),
  IN col VARCHAR(255),
  IN definition VARCHAR(1000)
)
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = tbl
      AND column_name = col
  ) THEN
    SET @sql = CONCAT(
      'ALTER TABLE `', tbl,
      '` ADD COLUMN `', col, '` ', definition
    );
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END $$

DROP PROCEDURE IF EXISTS drop_fk_if_exists $$
CREATE PROCEDURE drop_fk_if_exists(
  IN tbl VARCHAR(255),
  IN fk_name VARCHAR(255)
)
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_schema = DATABASE()
      AND table_name = tbl
      AND constraint_type = 'FOREIGN KEY'
      AND constraint_name = fk_name
  ) THEN
    SET @sql = CONCAT(
      'ALTER TABLE `', tbl,
      '` DROP FOREIGN KEY `', fk_name, '`'
    );
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END $$

DROP PROCEDURE IF EXISTS rename_table_if_exists $$
CREATE PROCEDURE rename_table_if_exists(
  IN old_name VARCHAR(255),
  IN new_name VARCHAR(255)
)
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = DATABASE()
      AND table_name = old_name
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = DATABASE()
      AND table_name = new_name
  ) THEN
    SET @sql = CONCAT(
      'RENAME TABLE `', old_name, '` TO `', new_name, '`'
    );
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END $$

DROP PROCEDURE IF EXISTS update_signed_up_teams_from_teams $$
CREATE PROCEDURE update_signed_up_teams_from_teams()
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'signed_up_teams'
      AND column_name = 'comments_for_advertisement'
  )
  AND EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'signed_up_teams'
      AND column_name = 'advertising_for_partner'
  )
  AND EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'teams'
      AND column_name = 'comments_for_advertisement'
  )
  AND EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'teams'
      AND column_name = 'advertise_for_partner'
  ) THEN
    SET @old_safe_updates = @@sql_safe_updates;
    SET SQL_SAFE_UPDATES = 0;

    SET @sql = '
      UPDATE signed_up_teams sut
      JOIN teams t ON sut.team_id = t.id
      SET
        sut.comments_for_advertisement = t.comments_for_advertisement,
        sut.advertising_for_partner = t.advertise_for_partner
    ';
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SET SQL_SAFE_UPDATES = @old_safe_updates;
  END IF;
END $$

DROP PROCEDURE IF EXISTS modify_column_if_exists $$
CREATE PROCEDURE modify_column_if_exists(
  IN tbl VARCHAR(255),
  IN col VARCHAR(255),
  IN definition VARCHAR(1000)
)
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = tbl
      AND column_name = col
  ) THEN
    SET @sql = CONCAT(
      'ALTER TABLE `', tbl,
      '` MODIFY COLUMN `', col, '` ', definition
    );
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END $$

DELIMITER ;

CALL rename_if_exists('account_requests','name','username','VARCHAR(255)');
CALL rename_if_exists('account_requests','fullname','name','VARCHAR(255)');

CALL rename_if_exists('assignment_questionnaires','notification_limit','notification_threshold','INT');
CALL rename_if_exists('assignment_questionnaires','dropdown','dropdown_in_use','TINYINT(1)');

CALL rename_if_exists('assignments','spec_location','URL','VARCHAR(255)');
CALL rename_if_exists('assignments','is_intelligent','topics_assigned_by_bidding','TINYINT(1)');
CALL rename_if_exists('assignments','availability_flag','available_to_students','TINYINT(1)');
CALL rename_if_exists('assignments','use_bookmark','can_bookmark_topics','TINYINT(1)');
CALL rename_if_exists('assignments','duty_based_assignment?','team_members_have_duties','TINYINT(1)');
CALL drop_column_if_exists('assignments','max_bids');
CALL drop_column_if_exists('assignments','reputation_algorithm');
CALL drop_column_if_exists('assignments','simicheck');
CALL drop_column_if_exists('assignments','simicheck_threshold');
CALL drop_column_if_exists('assignments','has_badge');
CALL drop_column_if_exists('assignments','is_conference_assignment');

CALL rename_if_exists('bookmark_ratings','bookmark_id','artifact_id','INT');
CALL rename_if_exists('bookmark_ratings','user_id','rater_id','BIGINT');
CALL rename_if_exists('bookmark_ratings','rating','ratings','INT');

CALL rename_if_exists('courses','private','is_private','TINYINT(1)');
CALL rename_if_exists('courses','institutions_id','institution_id','INT');
CALL rename_if_exists('courses','locale','language','VARCHAR(255)');

CALL rename_if_exists('due_dates','parent_id','assignment_id','INT');

CALL rename_if_exists('quiz_question_choices','iscorrect','is_correct','TINYINT(1)');

CALL rename_if_exists('response_maps','calibrate_to','for_calibration','INT');

CALL rename_if_exists('responses','map_id','response_map_id','INT');

CALL rename_if_exists('review_bids','signuptopic_id','project_topic_id','BIGINT');

CALL rename_if_exists('suggestions','unityID','username','VARCHAR(255)');

CALL rename_if_exists('users','name','username','VARCHAR(255)');
CALL rename_if_exists('users','fullname','name','VARCHAR(255)');
CALL rename_if_exists('users','timezonepref','time_zone_pref','VARCHAR(255)');
CALL drop_column_if_exists('users','mru_directory_path');
CALL drop_column_if_exists('users','email_on_review');
CALL drop_column_if_exists('users','email_on_review_of_review');
CALL drop_column_if_exists('users','master_permission_granted');
CALL drop_column_if_exists('users','digital_certificate');
CALL drop_column_if_exists('users','persistence_token');

-- Keep user_id aligned with users.id (bigint) to satisfy FK constraints
CALL modify_column_if_exists('participants','user_id','BIGINT FIRST');
CALL drop_column_if_exists('participants','submitted_at');
CALL drop_column_if_exists('participants','penalty_accumulated');
CALL drop_column_if_exists('participants','time_stamp');
CALL drop_column_if_exists('participants','digital_signature');
CALL drop_column_if_exists('participants','duty');
CALL drop_column_if_exists('participants','duty_id');
CALL drop_column_if_exists('participants','Hamer');
CALL drop_column_if_exists('participants','Lauw');
CALL rename_if_exists('participants','permission_granted','OK_to_show','BIT');
CALL add_column_if_not_exists('participants','can_mentor','BIT AFTER can_take_quiz');
CALL drop_fk_if_exists('participants','fk_rails_812e0f599c');
CALL drop_column_if_exists('participants','duty');
CALL drop_column_if_exists('participants','duty_id');

CALL drop_questionnaires_display_type();

CALL rename_if_exists('submission_records','type','record_type','TEXT');
CALL rename_if_exists('submission_records','user','submitted_by','VARCHAR(255)');
CALL drop_column_if_exists('submission_records','assignment_id');

CALL add_column_if_not_exists('signed_up_teams','comments_for_advertisement','TEXT');
CALL add_column_if_not_exists('signed_up_teams','advertising_for_partner','BOOLEAN DEFAULT FALSE');
CALL update_signed_up_teams_from_teams();

CALL drop_column_if_exists('teams','make_public');
CALL drop_column_if_exists('teams','comments_for_advertisement');
CALL drop_column_if_exists('teams','advertise_for_partner');

CALL rename_table_if_exists('teams_users','teams_participants');
CALL rename_table_if_exists('question_advices','question_advice');
CALL rename_table_if_exists('bids','topic_bids');

DROP TABLE IF EXISTS awarded_badges;
DROP TABLE IF EXISTS badges;
DROP TABLE IF EXISTS calculated_penalties;
DROP TABLE IF EXISTS delayed_jobs;
DROP TABLE IF EXISTS locks;
DROP TABLE IF EXISTS menu_items;
DROP TABLE IF EXISTS plagiarism_checker_assignment_submissions;
DROP TABLE IF EXISTS plagiarism_checker_comparisons;
DROP TABLE IF EXISTS sections;
DROP TABLE IF EXISTS system_settings;
DROP TABLE IF EXISTS automated_metareviews;
DROP TABLE IF EXISTS content_pages;
DROP TABLE IF EXISTS controller_actions;
DROP TABLE IF EXISTS markup_styles;
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS ar_internal_metadata;
DROP TABLE IF EXISTS site_controllers;

CREATE TABLE IF NOT EXISTS questionnaire_types (
  id INT AUTO_INCREMENT PRIMARY KEY,
  display_type VARCHAR(255) NOT NULL
);

SET FOREIGN_KEY_CHECKS = 1;
