USE expertiza_anonymization;
SET FOREIGN_KEY_CHECKS = 0;
DELIMITER $$

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
CALL rename_if_exists('bookmark_ratings','user_id','rater_id','INT');
CALL rename_if_exists('bookmark_ratings','rating','ratings','INT');

CALL rename_if_exists('courses','private','is_private','TINYINT(1)');
CALL rename_if_exists('courses','institutions_id','institution_id','INT');
CALL rename_if_exists('courses','locale','language','VARCHAR(255)');

CALL rename_if_exists('due_dates','parent_id','assignment_id','INT');

CALL rename_if_exists('quiz_question_choices','iscorrect','is_correct','TINYINT(1)');

CALL rename_if_exists('response_maps','calibrate_to','for_calibration','INT');

CALL rename_if_exists('responses','map_id','response_map_id','INT');

CALL rename_if_exists('review_bids','signuptopic_id','project_topic_id','INT');

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

CALL modify_column_if_exists('participants','user_id','INT(10) FIRST');
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
