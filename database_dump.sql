-- MySQL dump 10.13  Distrib 8.0.44, for Linux (x86_64)
--
-- Host: localhost    Database: reimplementation_development
-- ------------------------------------------------------
-- Server version	8.0.44

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `account_requests`
--

DROP TABLE IF EXISTS `account_requests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `account_requests` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `username` varchar(255) DEFAULT NULL,
  `full_name` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `status` varchar(255) DEFAULT NULL,
  `introduction` text,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `role_id` bigint NOT NULL,
  `institution_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_account_requests_on_institution_id` (`institution_id`),
  KEY `index_account_requests_on_role_id` (`role_id`),
  CONSTRAINT `fk_rails_39cb3df9b0` FOREIGN KEY (`institution_id`) REFERENCES `institutions` (`id`),
  CONSTRAINT `fk_rails_ea08ff5293` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `account_requests`
--

LOCK TABLES `account_requests` WRITE;
/*!40000 ALTER TABLE `account_requests` DISABLE KEYS */;
/*!40000 ALTER TABLE `account_requests` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `answers`
--

DROP TABLE IF EXISTS `answers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `answers` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `item_id` int NOT NULL DEFAULT '0',
  `response_id` int DEFAULT NULL,
  `answer` int DEFAULT NULL,
  `comments` text,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_score_items` (`item_id`),
  KEY `fk_score_response` (`response_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `answers`
--

LOCK TABLES `answers` WRITE;
/*!40000 ALTER TABLE `answers` DISABLE KEYS */;
/*!40000 ALTER TABLE `answers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ar_internal_metadata`
--

DROP TABLE IF EXISTS `ar_internal_metadata`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ar_internal_metadata` (
  `key` varchar(255) NOT NULL,
  `value` varchar(255) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ar_internal_metadata`
--

LOCK TABLES `ar_internal_metadata` WRITE;
/*!40000 ALTER TABLE `ar_internal_metadata` DISABLE KEYS */;
INSERT INTO `ar_internal_metadata` VALUES ('environment','development','2025-11-15 22:48:42.225557','2025-11-15 22:48:42.225561'),('schema_sha1','d6d04ca9ec9015eb33402a2bd419dfa8c6a07af4','2025-11-15 22:48:42.235203','2025-11-15 22:48:42.235205');
/*!40000 ALTER TABLE `ar_internal_metadata` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `assignment_questionnaires`
--

DROP TABLE IF EXISTS `assignment_questionnaires`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `assignment_questionnaires` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `assignment_id` int DEFAULT NULL,
  `questionnaire_id` int DEFAULT NULL,
  `notification_limit` int NOT NULL DEFAULT '15',
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `used_in_round` int DEFAULT NULL,
  `questionnaire_weight` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_aq_assignments_id` (`assignment_id`),
  KEY `fk_aq_questionnaire_id` (`questionnaire_id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `assignment_questionnaires`
--

LOCK TABLES `assignment_questionnaires` WRITE;
/*!40000 ALTER TABLE `assignment_questionnaires` DISABLE KEYS */;
INSERT INTO `assignment_questionnaires` VALUES (1,1,1,15,'2025-11-15 22:49:22.118717','2025-11-15 22:49:22.118717',1,NULL),(2,1,2,15,'2025-11-15 22:49:22.133606','2025-11-15 22:49:22.133606',2,NULL),(3,2,3,15,'2025-11-15 22:49:22.152366','2025-11-15 22:49:22.152366',1,NULL),(4,2,4,15,'2025-11-15 22:49:22.169158','2025-11-15 22:49:22.169158',2,NULL);
/*!40000 ALTER TABLE `assignment_questionnaires` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `assignments`
--

DROP TABLE IF EXISTS `assignments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `assignments` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `directory_path` varchar(255) DEFAULT NULL,
  `submitter_count` int DEFAULT NULL,
  `private` tinyint(1) DEFAULT NULL,
  `num_reviews` int DEFAULT NULL,
  `num_review_of_reviews` int DEFAULT NULL,
  `num_review_of_reviewers` int DEFAULT NULL,
  `reviews_visible_to_all` tinyint(1) DEFAULT NULL,
  `num_reviewers` int DEFAULT NULL,
  `spec_location` text,
  `max_team_size` int DEFAULT NULL,
  `staggered_deadline` tinyint(1) DEFAULT NULL,
  `allow_suggestions` tinyint(1) DEFAULT NULL,
  `days_between_submissions` int DEFAULT NULL,
  `review_assignment_strategy` varchar(255) DEFAULT NULL,
  `max_reviews_per_submission` int DEFAULT NULL,
  `review_topic_threshold` int DEFAULT NULL,
  `copy_flag` tinyint(1) DEFAULT NULL,
  `rounds_of_reviews` int DEFAULT NULL,
  `microtask` tinyint(1) DEFAULT NULL,
  `require_quiz` tinyint(1) DEFAULT NULL,
  `num_quiz_questions` int DEFAULT NULL,
  `is_coding_assignment` tinyint(1) DEFAULT NULL,
  `is_intelligent` tinyint(1) DEFAULT NULL,
  `calculate_penalty` tinyint(1) DEFAULT NULL,
  `late_policy_id` int DEFAULT NULL,
  `is_penalty_calculated` tinyint(1) DEFAULT NULL,
  `max_bids` int DEFAULT NULL,
  `show_teammate_reviews` tinyint(1) DEFAULT NULL,
  `availability_flag` tinyint(1) DEFAULT NULL,
  `use_bookmark` tinyint(1) DEFAULT NULL,
  `can_review_same_topic` tinyint(1) DEFAULT NULL,
  `can_choose_topic_to_review` tinyint(1) DEFAULT NULL,
  `is_calibrated` tinyint(1) DEFAULT NULL,
  `is_selfreview_enabled` tinyint(1) DEFAULT NULL,
  `reputation_algorithm` varchar(255) DEFAULT NULL,
  `is_anonymous` tinyint(1) DEFAULT NULL,
  `num_reviews_required` int DEFAULT NULL,
  `num_metareviews_required` int DEFAULT NULL,
  `num_metareviews_allowed` int DEFAULT NULL,
  `num_reviews_allowed` int DEFAULT NULL,
  `simicheck` int DEFAULT NULL,
  `simicheck_threshold` int DEFAULT NULL,
  `is_answer_tagging_allowed` tinyint(1) DEFAULT NULL,
  `has_badge` tinyint(1) DEFAULT NULL,
  `allow_selecting_additional_reviews_after_1st_round` tinyint(1) DEFAULT NULL,
  `sample_assignment_id` int DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `instructor_id` bigint NOT NULL,
  `course_id` bigint DEFAULT NULL,
  `enable_pair_programming` tinyint(1) DEFAULT '0',
  `has_teams` tinyint(1) DEFAULT '0',
  `has_topics` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `index_assignments_on_course_id` (`course_id`),
  KEY `index_assignments_on_instructor_id` (`instructor_id`),
  CONSTRAINT `fk_rails_2194c084a6` FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`),
  CONSTRAINT `fk_rails_e22e619567` FOREIGN KEY (`instructor_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `assignments`
--

LOCK TABLES `assignments` WRITE;
/*!40000 ALTER TABLE `assignments` DISABLE KEYS */;
INSERT INTO `assignments` VALUES (1,'audit',NULL,NULL,0,NULL,NULL,NULL,NULL,NULL,NULL,4,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2025-11-15 22:49:09.751586','2025-11-15 22:49:22.200267',8,2,0,1,1),(2,'encourage',NULL,NULL,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2025-11-15 22:49:09.769950','2025-11-15 22:49:09.769950',9,2,0,1,0),(3,'compel',NULL,NULL,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2025-11-15 22:49:09.782365','2025-11-15 22:49:09.782365',8,2,0,1,0),(4,'spray',NULL,NULL,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2025-11-15 22:49:09.801042','2025-11-15 22:49:09.801042',9,2,0,1,0),(5,'inspect',NULL,NULL,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2025-11-15 22:49:09.825501','2025-11-15 22:49:09.825501',8,2,0,1,0),(6,'impair',NULL,NULL,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2025-11-15 22:49:09.840605','2025-11-15 22:49:09.840605',9,2,0,1,0),(7,'wish',NULL,NULL,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2025-11-15 22:49:09.862102','2025-11-15 22:49:09.862102',8,2,0,1,0),(8,'bite',NULL,NULL,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2025-11-15 22:49:09.877849','2025-11-15 22:49:09.877849',9,2,0,1,0);
/*!40000 ALTER TABLE `assignments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `bookmark_ratings`
--

DROP TABLE IF EXISTS `bookmark_ratings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `bookmark_ratings` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `bookmark_id` int DEFAULT NULL,
  `user_id` int DEFAULT NULL,
  `rating` int DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `bookmark_ratings`
--

LOCK TABLES `bookmark_ratings` WRITE;
/*!40000 ALTER TABLE `bookmark_ratings` DISABLE KEYS */;
/*!40000 ALTER TABLE `bookmark_ratings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `bookmarks`
--

DROP TABLE IF EXISTS `bookmarks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `bookmarks` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `url` text,
  `title` text,
  `description` text,
  `user_id` int DEFAULT NULL,
  `topic_id` int DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `bookmarks`
--

LOCK TABLES `bookmarks` WRITE;
/*!40000 ALTER TABLE `bookmarks` DISABLE KEYS */;
/*!40000 ALTER TABLE `bookmarks` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cakes`
--

DROP TABLE IF EXISTS `cakes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cakes` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cakes`
--

LOCK TABLES `cakes` WRITE;
/*!40000 ALTER TABLE `cakes` DISABLE KEYS */;
/*!40000 ALTER TABLE `cakes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `courses`
--

DROP TABLE IF EXISTS `courses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `courses` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `directory_path` varchar(255) DEFAULT NULL,
  `info` text,
  `private` tinyint(1) DEFAULT '0',
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `instructor_id` bigint NOT NULL,
  `institution_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_courses_on_institution_id` (`institution_id`),
  KEY `fk_course_users` (`instructor_id`),
  KEY `index_courses_on_instructor_id` (`instructor_id`),
  CONSTRAINT `fk_rails_2ab3132eb0` FOREIGN KEY (`instructor_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_rails_d012129e83` FOREIGN KEY (`institution_id`) REFERENCES `institutions` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `courses`
--

LOCK TABLES `courses` WRITE;
/*!40000 ALTER TABLE `courses` DISABLE KEYS */;
INSERT INTO `courses` VALUES (1,'Military','ample_relationship/cruelty-angel','A fake class',0,'2025-11-15 22:49:09.610380','2025-11-15 22:49:09.610380',8,1),(2,'Oil & Energy','midnight-shock/ambiguous-corn','A fake class',0,'2025-11-15 22:49:09.628681','2025-11-15 22:49:09.628681',9,1);
/*!40000 ALTER TABLE `courses` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `due_dates`
--

DROP TABLE IF EXISTS `due_dates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `due_dates` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `due_at` datetime(6) NOT NULL,
  `deadline_type_id` int NOT NULL,
  `parent_type` varchar(255) NOT NULL,
  `parent_id` bigint NOT NULL,
  `submission_allowed_id` int NOT NULL,
  `review_allowed_id` int NOT NULL,
  `round` int DEFAULT NULL,
  `flag` tinyint(1) DEFAULT '0',
  `threshold` int DEFAULT '1',
  `delayed_job_id` varchar(255) DEFAULT NULL,
  `deadline_name` varchar(255) DEFAULT NULL,
  `description_url` varchar(255) DEFAULT NULL,
  `quiz_allowed_id` int DEFAULT '1',
  `teammate_review_allowed_id` int DEFAULT '3',
  `type` varchar(255) DEFAULT 'AssignmentDueDate',
  `resubmission_allowed_id` int DEFAULT NULL,
  `rereview_allowed_id` int DEFAULT NULL,
  `review_of_review_allowed_id` int DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_due_dates_on_parent` (`parent_type`,`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `due_dates`
--

LOCK TABLES `due_dates` WRITE;
/*!40000 ALTER TABLE `due_dates` DISABLE KEYS */;
/*!40000 ALTER TABLE `due_dates` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `institutions`
--

DROP TABLE IF EXISTS `institutions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `institutions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `institutions`
--

LOCK TABLES `institutions` WRITE;
/*!40000 ALTER TABLE `institutions` DISABLE KEYS */;
INSERT INTO `institutions` VALUES (1,'North Carolina State University','2025-11-15 22:49:03.488893','2025-11-15 22:49:03.488893');
/*!40000 ALTER TABLE `institutions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `invitations`
--

DROP TABLE IF EXISTS `invitations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `invitations` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `assignment_id` int DEFAULT NULL,
  `reply_status` varchar(1) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `from_id` bigint NOT NULL,
  `to_id` bigint NOT NULL,
  `participant_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_invitation_assignments` (`assignment_id`),
  KEY `index_invitations_on_from_id` (`from_id`),
  KEY `index_invitations_on_participant_id` (`participant_id`),
  KEY `index_invitations_on_to_id` (`to_id`),
  CONSTRAINT `fk_rails_5c28345ebb` FOREIGN KEY (`from_id`) REFERENCES `participants` (`id`),
  CONSTRAINT `fk_rails_9ac855df28` FOREIGN KEY (`to_id`) REFERENCES `participants` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `invitations`
--

LOCK TABLES `invitations` WRITE;
/*!40000 ALTER TABLE `invitations` DISABLE KEYS */;
/*!40000 ALTER TABLE `invitations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `items`
--

DROP TABLE IF EXISTS `items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `items` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `txt` text,
  `weight` int DEFAULT NULL,
  `seq` decimal(10,0) DEFAULT NULL,
  `question_type` varchar(255) DEFAULT NULL,
  `size` varchar(255) DEFAULT NULL,
  `alternatives` varchar(255) DEFAULT NULL,
  `break_before` tinyint(1) DEFAULT NULL,
  `max_label` varchar(255) DEFAULT NULL,
  `min_label` varchar(255) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `questionnaire_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_question_questionnaires` (`questionnaire_id`),
  KEY `index_items_on_questionnaire_id` (`questionnaire_id`),
  CONSTRAINT `fk_rails_c59f3245d3` FOREIGN KEY (`questionnaire_id`) REFERENCES `questionnaires` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=41 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `items`
--

LOCK TABLES `items` WRITE;
/*!40000 ALTER TABLE `items` DISABLE KEYS */;
INSERT INTO `items` VALUES (1,'Animi sequi voluptatem est ipsum asperiores quia architecto.',2,1,'Scale','50x3','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Assumenda','A','2025-11-15 22:49:21.438745','2025-11-15 22:49:21.438746',1),(2,'Earum a labore modi repellat eveniet consequuntur quasi.',2,2,'Criterion','40x2','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Recusandae','Eius','2025-11-15 22:49:21.475030','2025-11-15 22:49:21.475031',1),(3,'Ut natus perferendis quo id error et autem.',2,3,'Scale','60x4','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Est','Quidem','2025-11-15 22:49:21.488093','2025-11-15 22:49:21.488094',1),(4,'Eveniet eligendi consequuntur veritatis facilis explicabo commodi.',2,4,'TextArea','50x3','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Et','Quo','2025-11-15 22:49:21.502363','2025-11-15 22:49:21.502364',1),(5,'Eos impedit voluptate qui ullam ea ipsum atque.',1,5,'Dropdown','60x4','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Name','Nesciunt','2025-11-15 22:49:21.519869','2025-11-15 22:49:21.519870',1),(6,'Laudantium voluptas voluptatem non ut officiis quis deleniti.',2,6,'Criterion','50x3','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Et','Iure','2025-11-15 22:49:21.535449','2025-11-15 22:49:21.535449',1),(7,'Ut error et labore repellendus qui ex sapiente.',1,7,'TextArea','40x2','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Nulla','Dolorem','2025-11-15 22:49:21.547132','2025-11-15 22:49:21.547133',1),(8,'Tenetur adipisci illo voluptatem aut distinctio et velit.',2,8,'Dropdown','60x4','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Vitae','Hic','2025-11-15 22:49:21.564389','2025-11-15 22:49:21.564390',1),(9,'Et ut sit vel accusantium suscipit ipsum fugit.',1,9,'Dropdown','60x4','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Aliquam','Eveniet','2025-11-15 22:49:21.578295','2025-11-15 22:49:21.578295',1),(10,'Sit ipsum autem facere dolorum fugiat vel est.',2,10,'TextArea','60x4','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Et','Enim','2025-11-15 22:49:21.591428','2025-11-15 22:49:21.591429',1),(11,'Dolore quisquam pariatur quis perferendis ullam praesentium quas.',1,1,'Dropdown','50x3','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Dolores','Repellendus','2025-11-15 22:49:21.603968','2025-11-15 22:49:21.603969',2),(12,'Unde ad fugit tenetur autem ex aut provident.',2,2,'Dropdown','40x2','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'At','Ipsum','2025-11-15 22:49:21.619502','2025-11-15 22:49:21.619503',2),(13,'Molestiae molestiae amet sunt aliquam quia laboriosam deleniti.',1,3,'Dropdown','60x4','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Voluptas','Mollitia','2025-11-15 22:49:21.635878','2025-11-15 22:49:21.635879',2),(14,'Mollitia sed quae fuga doloremque cum sunt eveniet.',2,4,'Criterion','50x3','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Rerum','Cumque','2025-11-15 22:49:21.648978','2025-11-15 22:49:21.648978',2),(15,'Et iusto veniam quis eius rerum voluptas perferendis.',2,5,'Dropdown','50x3','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Rem','Quaerat','2025-11-15 22:49:21.663995','2025-11-15 22:49:21.663995',2),(16,'Voluptatem exercitationem dolores quia id aut quas voluptatibus.',2,6,'Scale','50x3','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Perspiciatis','Eos','2025-11-15 22:49:21.682033','2025-11-15 22:49:21.682033',2),(17,'Alias quos neque officia tempore dolorum expedita a.',2,7,'Criterion','50x3','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Facilis','Consequatur','2025-11-15 22:49:21.695772','2025-11-15 22:49:21.695772',2),(18,'Iure in quo fugit eos laudantium non est.',2,8,'Criterion','60x4','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Cum','Sint','2025-11-15 22:49:21.711042','2025-11-15 22:49:21.711042',2),(19,'Reprehenderit quis ut omnis corrupti est inventore sint.',1,9,'TextArea','60x4','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Sit','Accusantium','2025-11-15 22:49:21.727462','2025-11-15 22:49:21.727462',2),(20,'Et veniam nostrum quia quaerat provident officia ex.',2,10,'Dropdown','60x4','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Dolores','Laborum','2025-11-15 22:49:21.742467','2025-11-15 22:49:21.742467',2),(21,'Dolorem modi rerum esse eos voluptas placeat omnis.',1,1,'Scale','40x2','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Dolores','Name','2025-11-15 22:49:21.759247','2025-11-15 22:49:21.759248',3),(22,'Eveniet quia sit aut doloribus sapiente sequi illo.',1,2,'TextArea','50x3','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Amet','Minima','2025-11-15 22:49:21.777205','2025-11-15 22:49:21.777206',3),(23,'Veritatis doloribus cumque atque inventore molestiae facere qui.',1,3,'Criterion','40x2','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Qui','Possimus','2025-11-15 22:49:21.793967','2025-11-15 22:49:21.793968',3),(24,'Ipsam dolor ea id ducimus doloremque aliquid necessitatibus.',2,4,'Criterion','40x2','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Autem','Laudantium','2025-11-15 22:49:21.812252','2025-11-15 22:49:21.812253',3),(25,'Odio atque consequatur dolorem officiis quia autem nemo.',2,5,'Dropdown','60x4','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Occaecati','Neque','2025-11-15 22:49:21.826663','2025-11-15 22:49:21.826664',3),(26,'Pariatur et numquam est omnis dolores qui qui.',1,6,'TextArea','50x3','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Qui','Rerum','2025-11-15 22:49:21.842886','2025-11-15 22:49:21.842887',3),(27,'Qui sint nobis aut ab voluptas perspiciatis accusantium.',2,7,'Criterion','40x2','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Temporibus','Sint','2025-11-15 22:49:21.857543','2025-11-15 22:49:21.857544',3),(28,'Enim explicabo tenetur veniam temporibus sequi reprehenderit et.',2,8,'Dropdown','60x4','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Repellat','Sed','2025-11-15 22:49:21.871617','2025-11-15 22:49:21.871617',3),(29,'Dolores et cum debitis quibusdam est modi facere.',1,9,'Dropdown','50x3','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Cupiditate','Aut','2025-11-15 22:49:21.887063','2025-11-15 22:49:21.887063',3),(30,'Velit odit nemo hic quia numquam omnis nobis.',2,10,'Scale','60x4','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Quia','Consequatur','2025-11-15 22:49:21.903116','2025-11-15 22:49:21.903117',3),(31,'Nisi quo voluptatum velit eveniet aut rerum dolores.',2,1,'TextArea','60x4','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Beatae','Voluptates','2025-11-15 22:49:21.918620','2025-11-15 22:49:21.918621',4),(32,'Sed ut quos nulla magnam quas commodi ut.',2,2,'Criterion','50x3','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Aspernatur','Quas','2025-11-15 22:49:21.937170','2025-11-15 22:49:21.937171',4),(33,'Laboriosam earum veritatis voluptatibus quis quos quia nisi.',1,3,'TextArea','50x3','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Et','Quaerat','2025-11-15 22:49:21.954679','2025-11-15 22:49:21.954680',4),(34,'Ipsam exercitationem dolore dolores consequatur in nulla sit.',2,4,'Scale','60x4','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Recusandae','Amet','2025-11-15 22:49:21.972031','2025-11-15 22:49:21.972031',4),(35,'Rerum velit possimus nobis ipsam officiis ut eveniet.',2,5,'Scale','40x2','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Sit','Ut','2025-11-15 22:49:21.986587','2025-11-15 22:49:21.986588',4),(36,'Dolor commodi sit quidem a exercitationem cumque quia.',2,6,'Criterion','40x2','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Iure','Ratione','2025-11-15 22:49:22.001151','2025-11-15 22:49:22.001151',4),(37,'Ut a aliquam quod et quia aperiam praesentium.',2,7,'Dropdown','50x3','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Perspiciatis','Id','2025-11-15 22:49:22.017038','2025-11-15 22:49:22.017039',4),(38,'Recusandae error quas vitae aut harum velit corporis.',2,8,'Dropdown','40x2','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Eos','Quasi','2025-11-15 22:49:22.034568','2025-11-15 22:49:22.034568',4),(39,'Maxime sed quis sit corporis et molestias quas.',2,9,'Scale','40x2','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Saepe','Quis','2025-11-15 22:49:22.048509','2025-11-15 22:49:22.048510',4),(40,'Aut corporis debitis quia perspiciatis dolores optio accusantium.',2,10,'Dropdown','40x2','[\"Yes|No\", \"Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree\"]',1,'Et','Odio','2025-11-15 22:49:22.064913','2025-11-15 22:49:22.064913',4);
/*!40000 ALTER TABLE `items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `join_team_requests`
--

DROP TABLE IF EXISTS `join_team_requests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `join_team_requests` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `participant_id` int DEFAULT NULL,
  `team_id` int DEFAULT NULL,
  `comments` text,
  `reply_status` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `join_team_requests`
--

LOCK TABLES `join_team_requests` WRITE;
/*!40000 ALTER TABLE `join_team_requests` DISABLE KEYS */;
INSERT INTO `join_team_requests` VALUES (1,'2025-11-15 22:49:22.704123','2025-11-15 22:51:39.643432',51,17,'I have experience with Python and machine learning. Would love to contribute to the AI project!','ACCEPTED'),(2,'2025-11-15 22:49:22.726732','2025-11-15 22:54:20.540402',52,18,'I am proficient in React and Node.js. Can help with both frontend and backend!','ACCEPTED'),(3,'2025-11-15 22:49:22.745286','2025-11-15 22:54:00.155401',51,18,'Also interested in web development. Have full-stack experience.','DECLINED'),(4,'2025-11-15 22:49:22.765134','2025-11-15 22:49:22.765134',52,19,'Interested in mobile development!','DECLINED'),(5,'2025-11-15 22:56:24.018459','2025-11-15 22:59:53.082017',50,18,'Responding to advertisement for Web Development','ACCEPTED'),(6,'2025-11-15 22:58:09.167184','2025-11-15 22:59:59.909223',48,18,'Responding to advertisement for Web Development','ACCEPTED'),(7,'2025-11-15 22:59:05.290277','2025-11-15 22:59:05.290277',47,18,'Responding to advertisement for Web Development','PENDING'),(8,'2025-11-15 23:21:12.514923','2025-11-15 23:23:30.147394',49,17,'Responding to advertisement for AI and Machine Learning','ACCEPTED');
/*!40000 ALTER TABLE `join_team_requests` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `nodes`
--

DROP TABLE IF EXISTS `nodes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `nodes` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `parent_id` int DEFAULT NULL,
  `node_object_id` int DEFAULT NULL,
  `type` varchar(255) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `nodes`
--

LOCK TABLES `nodes` WRITE;
/*!40000 ALTER TABLE `nodes` DISABLE KEYS */;
/*!40000 ALTER TABLE `nodes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `participants`
--

DROP TABLE IF EXISTS `participants`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `participants` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `can_submit` tinyint(1) DEFAULT '1',
  `can_review` tinyint(1) DEFAULT '1',
  `handle` varchar(255) DEFAULT NULL,
  `permission_granted` tinyint(1) DEFAULT '0',
  `join_team_request_id` bigint DEFAULT NULL,
  `team_id` bigint DEFAULT NULL,
  `topic` varchar(255) DEFAULT NULL,
  `current_stage` varchar(255) DEFAULT NULL,
  `stage_deadline` datetime(6) DEFAULT NULL,
  `can_take_quiz` tinyint(1) DEFAULT NULL,
  `can_mentor` tinyint(1) DEFAULT NULL,
  `authorization` varchar(255) DEFAULT NULL,
  `parent_id` int NOT NULL,
  `type` varchar(255) NOT NULL,
  `grade` float DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_participants_on_join_team_request_id` (`join_team_request_id`),
  KEY `index_participants_on_team_id` (`team_id`),
  KEY `fk_participant_users` (`user_id`),
  KEY `index_participants_on_user_id` (`user_id`),
  CONSTRAINT `fk_rails_8cf3035ef1` FOREIGN KEY (`join_team_request_id`) REFERENCES `join_team_requests` (`id`),
  CONSTRAINT `fk_rails_990c37f108` FOREIGN KEY (`team_id`) REFERENCES `teams` (`id`),
  CONSTRAINT `fk_rails_b9a3c50f15` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=53 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `participants`
--

LOCK TABLES `participants` WRITE;
/*!40000 ALTER TABLE `participants` DISABLE KEYS */;
INSERT INTO `participants` VALUES (1,10,'2025-11-15 22:49:20.067974','2025-11-15 22:49:20.067974',1,1,'simon-rohan',0,NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,1,'AssignmentParticipant',NULL),(2,11,'2025-11-15 22:49:20.131044','2025-11-15 22:49:20.131044',1,1,'martine',0,NULL,2,NULL,NULL,NULL,NULL,NULL,NULL,1,'AssignmentParticipant',NULL),(3,12,'2025-11-15 22:49:20.164957','2025-11-15 22:49:20.164957',1,1,'joanne-reichert',0,NULL,3,NULL,NULL,NULL,NULL,NULL,NULL,1,'AssignmentParticipant',NULL),(4,13,'2025-11-15 22:49:20.201889','2025-11-15 22:49:20.201889',1,1,'antonetta',0,NULL,4,NULL,NULL,NULL,NULL,NULL,NULL,1,'AssignmentParticipant',NULL),(5,14,'2025-11-15 22:49:20.249710','2025-11-15 22:49:20.249710',1,1,'glenda',0,NULL,5,NULL,NULL,NULL,NULL,NULL,NULL,1,'AssignmentParticipant',NULL),(6,15,'2025-11-15 22:49:20.290664','2025-11-15 22:49:20.290664',1,1,'kenda',0,NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,1,'AssignmentParticipant',NULL),(7,16,'2025-11-15 22:49:20.323462','2025-11-15 22:49:20.323462',1,1,'ji',0,NULL,7,NULL,NULL,NULL,NULL,NULL,NULL,1,'AssignmentParticipant',NULL),(8,17,'2025-11-15 22:49:20.356540','2025-11-15 22:49:20.356540',1,1,'nelson',0,NULL,8,NULL,NULL,NULL,NULL,NULL,NULL,1,'AssignmentParticipant',NULL),(9,18,'2025-11-15 22:49:20.389857','2025-11-15 22:49:20.389857',1,1,'xavier',0,NULL,9,NULL,NULL,NULL,NULL,NULL,NULL,1,'AssignmentParticipant',NULL),(10,19,'2025-11-15 22:49:20.421129','2025-11-15 22:49:20.421129',1,1,'rose',0,NULL,10,NULL,NULL,NULL,NULL,NULL,NULL,1,'AssignmentParticipant',NULL),(11,20,'2025-11-15 22:49:20.456256','2025-11-15 22:49:20.456256',1,1,'lissa-keeling',0,NULL,11,NULL,NULL,NULL,NULL,NULL,NULL,1,'AssignmentParticipant',NULL),(12,21,'2025-11-15 22:49:20.496587','2025-11-15 22:49:20.496587',1,1,'jonathan-gulgowski',0,NULL,12,NULL,NULL,NULL,NULL,NULL,NULL,1,'AssignmentParticipant',NULL),(13,22,'2025-11-15 22:49:20.533512','2025-11-15 22:49:20.533512',1,1,'livia',0,NULL,13,NULL,NULL,NULL,NULL,NULL,NULL,1,'AssignmentParticipant',NULL),(14,23,'2025-11-15 22:49:20.564724','2025-11-15 22:49:20.564724',1,1,'janiece',0,NULL,14,NULL,NULL,NULL,NULL,NULL,NULL,1,'AssignmentParticipant',NULL),(15,24,'2025-11-15 22:49:20.598150','2025-11-15 22:49:20.598150',1,1,'jason',0,NULL,15,NULL,NULL,NULL,NULL,NULL,NULL,1,'AssignmentParticipant',NULL),(16,25,'2025-11-15 22:49:20.634535','2025-11-15 22:49:20.634535',1,1,'michel-mohr',0,NULL,16,NULL,NULL,NULL,NULL,NULL,NULL,1,'AssignmentParticipant',NULL),(17,26,'2025-11-15 22:49:20.670171','2025-11-15 22:49:20.670171',1,1,'wesley',0,NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,1,'AssignmentParticipant',NULL),(18,27,'2025-11-15 22:49:20.698796','2025-11-15 22:49:20.698796',1,1,'eileen',0,NULL,2,NULL,NULL,NULL,NULL,NULL,NULL,1,'AssignmentParticipant',NULL),(19,28,'2025-11-15 22:49:20.731918','2025-11-15 22:49:20.731918',1,1,'lynwood-medhurst',0,NULL,3,NULL,NULL,NULL,NULL,NULL,NULL,1,'AssignmentParticipant',NULL),(20,29,'2025-11-15 22:49:20.764580','2025-11-15 22:49:20.764580',1,1,'ira',0,NULL,4,NULL,NULL,NULL,NULL,NULL,NULL,1,'AssignmentParticipant',NULL),(21,30,'2025-11-15 22:49:20.799624','2025-11-15 22:49:20.799624',1,1,'gavin',0,NULL,5,NULL,NULL,NULL,NULL,NULL,NULL,1,'AssignmentParticipant',NULL),(22,31,'2025-11-15 22:49:20.835038','2025-11-15 22:49:20.835038',1,1,'anthony',0,NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,1,'AssignmentParticipant',NULL),(23,32,'2025-11-15 22:49:20.872685','2025-11-15 22:49:20.872685',1,1,'anthony-schuppe',0,NULL,7,NULL,NULL,NULL,NULL,NULL,NULL,1,'AssignmentParticipant',NULL),(24,33,'2025-11-15 22:49:20.931834','2025-11-15 22:49:20.931834',1,1,'julieann',0,NULL,8,NULL,NULL,NULL,NULL,NULL,NULL,2,'CourseParticipant',NULL),(25,34,'2025-11-15 22:49:20.948191','2025-11-15 22:49:20.948191',1,1,'milton-sanford',0,NULL,9,NULL,NULL,NULL,NULL,NULL,NULL,1,'CourseParticipant',NULL),(26,35,'2025-11-15 22:49:20.963813','2025-11-15 22:49:20.963813',1,1,'colin-stracke',0,NULL,10,NULL,NULL,NULL,NULL,NULL,NULL,2,'CourseParticipant',NULL),(27,36,'2025-11-15 22:49:20.980149','2025-11-15 22:49:20.980149',1,1,'rigoberto-oberbrunner',0,NULL,11,NULL,NULL,NULL,NULL,NULL,NULL,1,'CourseParticipant',NULL),(28,37,'2025-11-15 22:49:20.994813','2025-11-15 22:49:20.994813',1,1,'vern-blick',0,NULL,12,NULL,NULL,NULL,NULL,NULL,NULL,2,'CourseParticipant',NULL),(29,38,'2025-11-15 22:49:21.010647','2025-11-15 22:49:21.010647',1,1,'janyce',0,NULL,13,NULL,NULL,NULL,NULL,NULL,NULL,1,'CourseParticipant',NULL),(30,39,'2025-11-15 22:49:21.023602','2025-11-15 22:49:21.023602',1,1,'kerrie-hane',0,NULL,14,NULL,NULL,NULL,NULL,NULL,NULL,2,'CourseParticipant',NULL),(31,40,'2025-11-15 22:49:21.043091','2025-11-15 22:49:21.043091',1,1,'jerald',0,NULL,15,NULL,NULL,NULL,NULL,NULL,NULL,1,'CourseParticipant',NULL),(32,41,'2025-11-15 22:49:21.068544','2025-11-15 22:49:21.068544',1,1,'kylie-beier',0,NULL,16,NULL,NULL,NULL,NULL,NULL,NULL,2,'CourseParticipant',NULL),(33,42,'2025-11-15 22:49:21.095117','2025-11-15 22:49:21.095117',1,1,'willian-hirthe',0,NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,1,'CourseParticipant',NULL),(34,43,'2025-11-15 22:49:21.110682','2025-11-15 22:49:21.110682',1,1,'vincent',0,NULL,2,NULL,NULL,NULL,NULL,NULL,NULL,2,'CourseParticipant',NULL),(35,44,'2025-11-15 22:49:21.125655','2025-11-15 22:49:21.125655',1,1,'kayla',0,NULL,3,NULL,NULL,NULL,NULL,NULL,NULL,1,'CourseParticipant',NULL),(36,45,'2025-11-15 22:49:21.143264','2025-11-15 22:49:21.143264',1,1,'hung',0,NULL,4,NULL,NULL,NULL,NULL,NULL,NULL,2,'CourseParticipant',NULL),(37,46,'2025-11-15 22:49:21.160411','2025-11-15 22:49:21.160411',1,1,'ermelinda-mills',0,NULL,5,NULL,NULL,NULL,NULL,NULL,NULL,1,'CourseParticipant',NULL),(38,47,'2025-11-15 22:49:21.172396','2025-11-15 22:49:21.172396',1,1,'whitney',0,NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,2,'CourseParticipant',NULL),(39,48,'2025-11-15 22:49:21.185994','2025-11-15 22:49:21.185994',1,1,'sergio',0,NULL,7,NULL,NULL,NULL,NULL,NULL,NULL,1,'CourseParticipant',NULL),(40,49,'2025-11-15 22:49:21.202478','2025-11-15 22:49:21.202478',1,1,'stanford',0,NULL,8,NULL,NULL,NULL,NULL,NULL,NULL,2,'CourseParticipant',NULL),(41,50,'2025-11-15 22:49:21.217308','2025-11-15 22:49:21.217308',1,1,'margene',0,NULL,9,NULL,NULL,NULL,NULL,NULL,NULL,1,'CourseParticipant',NULL),(42,51,'2025-11-15 22:49:21.233449','2025-11-15 22:49:21.233449',1,1,'wanda-oreilly',0,NULL,10,NULL,NULL,NULL,NULL,NULL,NULL,2,'CourseParticipant',NULL),(43,52,'2025-11-15 22:49:21.254452','2025-11-15 22:49:21.254452',1,1,'james',0,NULL,11,NULL,NULL,NULL,NULL,NULL,NULL,1,'CourseParticipant',NULL),(44,53,'2025-11-15 22:49:21.269216','2025-11-15 22:49:21.269216',1,1,'gregory',0,NULL,12,NULL,NULL,NULL,NULL,NULL,NULL,2,'CourseParticipant',NULL),(45,54,'2025-11-15 22:49:21.283245','2025-11-15 22:49:21.283245',1,1,'johnie-zemlak',0,NULL,13,NULL,NULL,NULL,NULL,NULL,NULL,1,'CourseParticipant',NULL),(46,55,'2025-11-15 22:49:21.298326','2025-11-15 22:49:21.298326',1,1,'erline',0,NULL,14,NULL,NULL,NULL,NULL,NULL,NULL,2,'CourseParticipant',NULL),(47,2,'2025-11-15 22:49:22.304114','2025-11-15 22:49:22.456587',1,1,'alice',0,NULL,17,NULL,NULL,NULL,NULL,NULL,NULL,1,'AssignmentParticipant',NULL),(48,3,'2025-11-15 22:49:22.319883','2025-11-15 22:49:22.465496',1,1,'bob',0,NULL,17,NULL,NULL,NULL,NULL,NULL,NULL,1,'AssignmentParticipant',NULL),(49,4,'2025-11-15 22:49:22.334399','2025-11-15 22:49:22.558760',1,1,'charlie',0,NULL,18,NULL,NULL,NULL,NULL,NULL,NULL,1,'AssignmentParticipant',NULL),(50,5,'2025-11-15 22:49:22.349995','2025-11-15 22:49:22.631453',1,1,'diana',0,NULL,19,NULL,NULL,NULL,NULL,NULL,NULL,1,'AssignmentParticipant',NULL),(51,6,'2025-11-15 22:49:22.367524','2025-11-15 22:49:22.367524',1,1,'ethan',0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'AssignmentParticipant',NULL),(52,7,'2025-11-15 22:49:22.384185','2025-11-15 22:49:22.384185',1,1,'fiona',0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'AssignmentParticipant',NULL);
/*!40000 ALTER TABLE `participants` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `question_advices`
--

DROP TABLE IF EXISTS `question_advices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `question_advices` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `question_id` bigint NOT NULL,
  `score` int DEFAULT NULL,
  `advice` text,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_question_advices_on_question_id` (`question_id`),
  CONSTRAINT `fk_rails_e2f223545a` FOREIGN KEY (`question_id`) REFERENCES `items` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `question_advices`
--

LOCK TABLES `question_advices` WRITE;
/*!40000 ALTER TABLE `question_advices` DISABLE KEYS */;
/*!40000 ALTER TABLE `question_advices` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `question_types`
--

DROP TABLE IF EXISTS `question_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `question_types` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `question_types`
--

LOCK TABLES `question_types` WRITE;
/*!40000 ALTER TABLE `question_types` DISABLE KEYS */;
/*!40000 ALTER TABLE `question_types` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `questionnaire_types`
--

DROP TABLE IF EXISTS `questionnaire_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `questionnaire_types` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `questionnaire_types`
--

LOCK TABLES `questionnaire_types` WRITE;
/*!40000 ALTER TABLE `questionnaire_types` DISABLE KEYS */;
/*!40000 ALTER TABLE `questionnaire_types` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `questionnaires`
--

DROP TABLE IF EXISTS `questionnaires`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `questionnaires` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `instructor_id` int DEFAULT NULL,
  `private` tinyint(1) DEFAULT NULL,
  `min_question_score` int DEFAULT NULL,
  `max_question_score` int DEFAULT NULL,
  `questionnaire_type` varchar(255) DEFAULT NULL,
  `display_type` varchar(255) DEFAULT NULL,
  `instruction_loc` text,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `questionnaires`
--

LOCK TABLES `questionnaires` WRITE;
/*!40000 ALTER TABLE `questionnaires` DISABLE KEYS */;
INSERT INTO `questionnaires` VALUES (1,'Ab Et Nesciunt Corrupti Dolore',4,0,0,5,'ReviewQuestionnaire','Review',NULL,'2025-11-15 22:49:21.326436','2025-11-15 22:49:21.326436'),(2,'Adipisci Qui Voluptatem Quidem Ipsum',3,0,0,5,'ReviewQuestionnaire','Review',NULL,'2025-11-15 22:49:21.375613','2025-11-15 22:49:21.375614'),(3,'Vel Minus Vero Eum Dolores',1,0,0,5,'ReviewQuestionnaire','Review',NULL,'2025-11-15 22:49:21.387979','2025-11-15 22:49:21.387979'),(4,'Eaque Aut A Blanditiis Similique',3,0,0,5,'ReviewQuestionnaire','Review',NULL,'2025-11-15 22:49:21.404540','2025-11-15 22:49:21.404541');
/*!40000 ALTER TABLE `questionnaires` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `quiz_question_choices`
--

DROP TABLE IF EXISTS `quiz_question_choices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `quiz_question_choices` (
  `id` int NOT NULL AUTO_INCREMENT,
  `question_id` int DEFAULT NULL,
  `txt` text,
  `iscorrect` tinyint(1) DEFAULT '0',
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `quiz_question_choices`
--

LOCK TABLES `quiz_question_choices` WRITE;
/*!40000 ALTER TABLE `quiz_question_choices` DISABLE KEYS */;
/*!40000 ALTER TABLE `quiz_question_choices` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `response_maps`
--

DROP TABLE IF EXISTS `response_maps`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `response_maps` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `reviewed_object_id` int NOT NULL DEFAULT '0',
  `reviewer_id` int NOT NULL DEFAULT '0',
  `reviewee_id` int NOT NULL DEFAULT '0',
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `type` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_response_map_reviewer` (`reviewer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `response_maps`
--

LOCK TABLES `response_maps` WRITE;
/*!40000 ALTER TABLE `response_maps` DISABLE KEYS */;
/*!40000 ALTER TABLE `response_maps` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `responses`
--

DROP TABLE IF EXISTS `responses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `responses` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `map_id` int NOT NULL DEFAULT '0',
  `additional_comment` text,
  `is_submitted` tinyint(1) DEFAULT '0',
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `round` int DEFAULT NULL,
  `version_num` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_response_response_map` (`map_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `responses`
--

LOCK TABLES `responses` WRITE;
/*!40000 ALTER TABLE `responses` DISABLE KEYS */;
/*!40000 ALTER TABLE `responses` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `roles`
--

DROP TABLE IF EXISTS `roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `roles` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `parent_id` bigint DEFAULT NULL,
  `default_page_id` int DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_rails_4404228d2f` (`parent_id`),
  CONSTRAINT `fk_rails_4404228d2f` FOREIGN KEY (`parent_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `roles`
--

LOCK TABLES `roles` WRITE;
/*!40000 ALTER TABLE `roles` DISABLE KEYS */;
INSERT INTO `roles` VALUES (1,'Super Administrator',NULL,NULL,'2025-11-15 22:49:03.561397','2025-11-15 22:49:03.561397'),(2,'Administrator',NULL,NULL,'2025-11-15 22:49:03.580891','2025-11-15 22:49:03.580891'),(3,'Instructor',NULL,NULL,'2025-11-15 22:49:03.603641','2025-11-15 22:49:03.603641'),(4,'Teaching Assistant',NULL,NULL,'2025-11-15 22:49:03.621059','2025-11-15 22:49:03.621059'),(5,'Student',NULL,NULL,'2025-11-15 22:49:03.643916','2025-11-15 22:49:03.643916');
/*!40000 ALTER TABLE `roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `schema_migrations`
--

DROP TABLE IF EXISTS `schema_migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `schema_migrations` (
  `version` varchar(255) NOT NULL,
  PRIMARY KEY (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `schema_migrations`
--

LOCK TABLES `schema_migrations` WRITE;
/*!40000 ALTER TABLE `schema_migrations` DISABLE KEYS */;
INSERT INTO `schema_migrations` VALUES ('20230305064753'),('20230305185139'),('20230306022503'),('20230306035806'),('20230401213353'),('20230401213404'),('20230412013301'),('20230412013310'),('20230412020156'),('20230415003243'),('20230415011209'),('20230424172126'),('20230424172612'),('20230424173506'),('20230424174001'),('20230424174153'),('20230427171632'),('20231019170608'),('20231019195109'),('20231026002451'),('20231026002543'),('20231027211715'),('20231028012101'),('20231030174450'),('20231102173153'),('20231104070639'),('20231104071922'),('20231105193016'),('20231105193219'),('20231129021640'),('20231129023417'),('20231129024913'),('20231129050431'),('20231129051018'),('20231130030500'),('20231130030611'),('20231130030646'),('20231130033226'),('20231130033325'),('20231130033332'),('20231201012040'),('20231201024204'),('20240318205124'),('20240324000112'),('20240415155554'),('20240415163413'),('20240415192048'),('20240420000000'),('20240420070000'),('20241015223136'),('20241201224112'),('20241201224137'),('20241202165201'),('20250214224716'),('20250216020117'),('20250324193058'),('20250401020016'),('20250414002952'),('20250414005152'),('20250418004442'),('20250418013852'),('20250418014519'),('20250427014225'),('20250621151644'),('20250621152946'),('20250621180527'),('20250621180851'),('20250629185100'),('20250629185439'),('20250629190818'),('20250727170825'),('20250805174104'),('20251021165336'),('20251022160053'),('20251029071649');
/*!40000 ALTER TABLE `schema_migrations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sign_up_topics`
--

DROP TABLE IF EXISTS `sign_up_topics`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sign_up_topics` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `topic_name` text NOT NULL,
  `assignment_id` bigint NOT NULL,
  `max_choosers` int NOT NULL DEFAULT '0',
  `category` text,
  `topic_identifier` varchar(10) DEFAULT NULL,
  `micropayment` int DEFAULT '0',
  `private_to` int DEFAULT NULL,
  `description` text,
  `link` varchar(255) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_sign_up_categories_sign_up_topics` (`assignment_id`),
  KEY `index_sign_up_topics_on_assignment_id` (`assignment_id`),
  CONSTRAINT `fk_rails_c15a869a32` FOREIGN KEY (`assignment_id`) REFERENCES `assignments` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sign_up_topics`
--

LOCK TABLES `sign_up_topics` WRITE;
/*!40000 ALTER TABLE `sign_up_topics` DISABLE KEYS */;
INSERT INTO `sign_up_topics` VALUES (1,'AI and Machine Learning',1,2,NULL,NULL,0,NULL,'Research on artificial intelligence applications',NULL,'2025-11-15 22:49:22.252164','2025-11-15 22:49:22.252164'),(2,'Web Development',1,2,NULL,NULL,0,NULL,'Modern web development frameworks and tools',NULL,'2025-11-15 22:49:22.266382','2025-11-15 22:49:22.266382'),(3,'Mobile Applications',1,2,NULL,NULL,0,NULL,'iOS and Android app development',NULL,'2025-11-15 22:49:22.286811','2025-11-15 22:49:22.286811');
/*!40000 ALTER TABLE `sign_up_topics` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `signed_up_teams`
--

DROP TABLE IF EXISTS `signed_up_teams`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `signed_up_teams` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `sign_up_topic_id` bigint NOT NULL,
  `team_id` bigint NOT NULL,
  `is_waitlisted` tinyint(1) DEFAULT NULL,
  `preference_priority_number` int DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `comments_for_advertisement` text,
  `advertise_for_partner` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_signed_up_teams_on_sign_up_topic_id` (`sign_up_topic_id`),
  KEY `index_signed_up_teams_on_team_id` (`team_id`),
  CONSTRAINT `fk_rails_b3a6d3624c` FOREIGN KEY (`team_id`) REFERENCES `teams` (`id`),
  CONSTRAINT `fk_rails_f886024d81` FOREIGN KEY (`sign_up_topic_id`) REFERENCES `sign_up_topics` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `signed_up_teams`
--

LOCK TABLES `signed_up_teams` WRITE;
/*!40000 ALTER TABLE `signed_up_teams` DISABLE KEYS */;
INSERT INTO `signed_up_teams` VALUES (1,1,17,0,NULL,'2025-11-15 22:49:22.516383','2025-11-15 22:49:22.516383','Python &AND& TensorFlow &AND& Data Science',1),(2,2,18,0,NULL,'2025-11-15 22:49:22.579260','2025-11-15 22:49:22.579260','React &AND& Node.js &AND& TypeScript',1),(3,3,19,0,NULL,'2025-11-15 22:49:22.649225','2025-11-15 22:49:22.649225',NULL,0);
/*!40000 ALTER TABLE `signed_up_teams` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ta_mappings`
--

DROP TABLE IF EXISTS `ta_mappings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ta_mappings` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `course_id` bigint NOT NULL,
  `user_id` bigint NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_ta_mappings_on_course_id` (`course_id`),
  KEY `fk_ta_mapping_users` (`user_id`),
  KEY `index_ta_mappings_on_user_id` (`user_id`),
  CONSTRAINT `fk_rails_3db3e2b248` FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`),
  CONSTRAINT `fk_rails_f98655c908` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ta_mappings`
--

LOCK TABLES `ta_mappings` WRITE;
/*!40000 ALTER TABLE `ta_mappings` DISABLE KEYS */;
/*!40000 ALTER TABLE `ta_mappings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `teams`
--

DROP TABLE IF EXISTS `teams`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `teams` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `name` varchar(255) NOT NULL,
  `type` varchar(255) NOT NULL,
  `parent_id` int NOT NULL,
  `grade_for_submission` int DEFAULT NULL,
  `comment_for_submission` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `teams`
--

LOCK TABLES `teams` WRITE;
/*!40000 ALTER TABLE `teams` DISABLE KEYS */;
INSERT INTO `teams` VALUES (1,'2025-11-15 22:49:09.978170','2025-11-15 22:49:09.978170','denice','AssignmentTeam',1,NULL,NULL),(2,'2025-11-15 22:49:09.993937','2025-11-15 22:49:09.993937','adan stoltenberg','AssignmentTeam',1,NULL,NULL),(3,'2025-11-15 22:49:10.009747','2025-11-15 22:49:10.009747','sang','AssignmentTeam',1,NULL,NULL),(4,'2025-11-15 22:49:10.026409','2025-11-15 22:49:10.026409','herb','AssignmentTeam',1,NULL,NULL),(5,'2025-11-15 22:49:10.044312','2025-11-15 22:49:10.044312','giuseppe wiegand','AssignmentTeam',1,NULL,NULL),(6,'2025-11-15 22:49:10.077570','2025-11-15 22:49:10.077570','delia rogahn','AssignmentTeam',1,NULL,NULL),(7,'2025-11-15 22:49:10.176154','2025-11-15 22:49:10.176154','jordon spencer','AssignmentTeam',1,NULL,NULL),(8,'2025-11-15 22:49:10.190295','2025-11-15 22:49:10.190295','cruz','AssignmentTeam',1,NULL,NULL),(9,'2025-11-15 22:49:10.224191','2025-11-15 22:49:10.224191','lakeshia borer','CourseTeam',2,NULL,NULL),(10,'2025-11-15 22:49:10.240950','2025-11-15 22:49:10.240950','roni grimes','CourseTeam',2,NULL,NULL),(11,'2025-11-15 22:49:10.254785','2025-11-15 22:49:10.254785','gary predovic','CourseTeam',2,NULL,NULL),(12,'2025-11-15 22:49:10.279512','2025-11-15 22:49:10.279512','moses jakubowski','CourseTeam',2,NULL,NULL),(13,'2025-11-15 22:49:10.309244','2025-11-15 22:49:10.309244','gita','CourseTeam',2,NULL,NULL),(14,'2025-11-15 22:49:10.333895','2025-11-15 22:49:10.333895','machelle','CourseTeam',2,NULL,NULL),(15,'2025-11-15 22:49:10.349560','2025-11-15 22:49:10.349560','daine corkery','CourseTeam',2,NULL,NULL),(16,'2025-11-15 22:49:10.370800','2025-11-15 22:49:10.370800','verline','CourseTeam',2,NULL,NULL),(17,'2025-11-15 22:49:22.399739','2025-11-15 22:49:22.399739','AI Innovators','AssignmentTeam',1,NULL,NULL),(18,'2025-11-15 22:49:22.531058','2025-11-15 22:49:22.531058','Web Warriors','AssignmentTeam',1,NULL,NULL),(19,'2025-11-15 22:49:22.594653','2025-11-15 22:49:22.594653','Mobile Masters','AssignmentTeam',1,NULL,NULL);
/*!40000 ALTER TABLE `teams` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `teams_participants`
--

DROP TABLE IF EXISTS `teams_participants`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `teams_participants` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `team_id` bigint NOT NULL,
  `duty_id` int DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `participant_id` bigint NOT NULL,
  `user_id` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_teams_participants_on_participant_id` (`participant_id`),
  KEY `index_teams_participants_on_team_id` (`team_id`),
  KEY `index_teams_participants_on_user_id` (`user_id`),
  CONSTRAINT `fk_rails_f4d20198de` FOREIGN KEY (`participant_id`) REFERENCES `participants` (`id`),
  CONSTRAINT `fk_rails_fc217eb52e` FOREIGN KEY (`team_id`) REFERENCES `teams` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=33 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `teams_participants`
--

LOCK TABLES `teams_participants` WRITE;
/*!40000 ALTER TABLE `teams_participants` DISABLE KEYS */;
INSERT INTO `teams_participants` VALUES (1,1,NULL,'2025-11-15 22:49:20.120273','2025-11-15 22:49:20.120273',1,10),(2,2,NULL,'2025-11-15 22:49:20.151957','2025-11-15 22:49:20.151957',2,11),(3,3,NULL,'2025-11-15 22:49:20.187710','2025-11-15 22:49:20.187710',3,12),(4,4,NULL,'2025-11-15 22:49:20.230627','2025-11-15 22:49:20.230627',4,13),(5,5,NULL,'2025-11-15 22:49:20.273339','2025-11-15 22:49:20.273339',5,14),(6,6,NULL,'2025-11-15 22:49:20.312217','2025-11-15 22:49:20.312217',6,15),(7,7,NULL,'2025-11-15 22:49:20.343751','2025-11-15 22:49:20.343751',7,16),(8,8,NULL,'2025-11-15 22:49:20.376074','2025-11-15 22:49:20.376074',8,17),(9,9,NULL,'2025-11-15 22:49:20.409146','2025-11-15 22:49:20.409146',9,18),(10,10,NULL,'2025-11-15 22:49:20.440938','2025-11-15 22:49:20.440938',10,19),(11,11,NULL,'2025-11-15 22:49:20.482101','2025-11-15 22:49:20.482101',11,20),(12,12,NULL,'2025-11-15 22:49:20.519310','2025-11-15 22:49:20.519310',12,21),(13,13,NULL,'2025-11-15 22:49:20.552850','2025-11-15 22:49:20.552850',13,22),(14,14,NULL,'2025-11-15 22:49:20.586153','2025-11-15 22:49:20.586153',14,23),(15,15,NULL,'2025-11-15 22:49:20.621640','2025-11-15 22:49:20.621640',15,24),(16,16,NULL,'2025-11-15 22:49:20.657731','2025-11-15 22:49:20.657731',16,25),(17,1,NULL,'2025-11-15 22:49:20.687672','2025-11-15 22:49:20.687672',17,26),(18,2,NULL,'2025-11-15 22:49:20.719120','2025-11-15 22:49:20.719120',18,27),(19,3,NULL,'2025-11-15 22:49:20.752424','2025-11-15 22:49:20.752424',19,28),(20,4,NULL,'2025-11-15 22:49:20.785478','2025-11-15 22:49:20.785478',20,29),(21,5,NULL,'2025-11-15 22:49:20.821631','2025-11-15 22:49:20.821631',21,30),(22,6,NULL,'2025-11-15 22:49:20.857609','2025-11-15 22:49:20.857609',22,31),(23,7,NULL,'2025-11-15 22:49:20.891295','2025-11-15 22:49:20.891295',23,32),(24,17,NULL,'2025-11-15 22:49:22.426925','2025-11-15 22:49:22.426925',47,2),(25,17,NULL,'2025-11-15 22:49:22.447826','2025-11-15 22:49:22.447826',48,3),(26,18,NULL,'2025-11-15 22:49:22.550799','2025-11-15 22:49:22.550799',49,4),(27,19,NULL,'2025-11-15 22:49:22.619734','2025-11-15 22:49:22.619734',50,5),(28,17,NULL,'2025-11-15 22:51:39.631775','2025-11-15 22:51:39.631775',51,6),(29,18,NULL,'2025-11-15 22:54:20.533274','2025-11-15 22:54:20.533274',52,7),(30,18,NULL,'2025-11-15 22:59:53.075085','2025-11-15 22:59:53.075085',50,5),(31,18,NULL,'2025-11-15 22:59:59.901036','2025-11-15 22:59:59.901036',48,3),(32,17,NULL,'2025-11-15 23:23:30.137080','2025-11-15 23:23:30.137080',49,4);
/*!40000 ALTER TABLE `teams_participants` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `teams_users`
--

DROP TABLE IF EXISTS `teams_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `teams_users` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `team_id` bigint NOT NULL,
  `user_id` bigint NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_teams_users_on_team_id` (`team_id`),
  KEY `index_teams_users_on_user_id` (`user_id`),
  CONSTRAINT `fk_rails_74983f37ec` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_rails_7caef73a94` FOREIGN KEY (`team_id`) REFERENCES `teams` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `teams_users`
--

LOCK TABLES `teams_users` WRITE;
/*!40000 ALTER TABLE `teams_users` DISABLE KEYS */;
/*!40000 ALTER TABLE `teams_users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `password_digest` varchar(255) DEFAULT NULL,
  `full_name` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `mru_directory_path` varchar(255) DEFAULT NULL,
  `email_on_review` tinyint(1) DEFAULT '0',
  `email_on_submission` tinyint(1) DEFAULT '0',
  `email_on_review_of_review` tinyint(1) DEFAULT '0',
  `is_new_user` tinyint(1) DEFAULT '1',
  `master_permission_granted` tinyint(1) DEFAULT '0',
  `handle` varchar(255) DEFAULT NULL,
  `persistence_token` varchar(255) DEFAULT NULL,
  `timeZonePref` varchar(255) DEFAULT NULL,
  `copy_of_emails` tinyint(1) DEFAULT '0',
  `etc_icons_on_homepage` tinyint(1) DEFAULT '0',
  `locale` int DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `institution_id` bigint DEFAULT NULL,
  `role_id` bigint NOT NULL,
  `parent_id` bigint DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_users_on_institution_id` (`institution_id`),
  KEY `index_users_on_parent_id` (`parent_id`),
  KEY `index_users_on_role_id` (`role_id`),
  CONSTRAINT `fk_rails_642f17018b` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`),
  CONSTRAINT `fk_rails_684a13307d` FOREIGN KEY (`parent_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_rails_7fcf39ca13` FOREIGN KEY (`institution_id`) REFERENCES `institutions` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=56 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'admin','$2a$12$Vx8Y.xeROXxiS/L0y/V1lOAPNDRU61X698xqy23ZTOFFEQxdydnwS','admin admin','admin2@example.com',NULL,0,0,0,1,0,NULL,NULL,NULL,0,1,NULL,'2025-11-15 22:49:04.137704','2025-11-15 22:49:04.137704',1,1,NULL),(2,'alice','$2a$12$MY4nYh9fMeKYLJgZq/VmTuD3k2txq0wFhQnpDO4hcLy0TsPHMdGWC','Alice Johnson','alice@example.com',NULL,0,0,0,1,0,'alice',NULL,NULL,0,1,NULL,'2025-11-15 22:49:05.271823','2025-11-15 22:49:05.271823',1,5,NULL),(3,'bob','$2a$12$QBigs3zR7OX0O9tvjC0XROMA938IBxN9xYf082No4ANivlTPK88Na','Bob Smith','bob@example.com',NULL,0,0,0,1,0,'bob',NULL,NULL,0,1,NULL,'2025-11-15 22:49:06.475531','2025-11-15 22:49:06.475531',1,5,NULL),(4,'charlie','$2a$12$Q343KEH76jtMUXbpHjgd8.UsjsQffk.T6KGeXEnKtcRWjLt19Yh0C','Charlie Davis','charlie@example.com',NULL,0,0,0,1,0,'charlie',NULL,NULL,0,1,NULL,'2025-11-15 22:49:06.700163','2025-11-15 22:49:06.700163',1,5,NULL),(5,'diana','$2a$12$VNyl5.UMIv/IbgvyMHF4W.8hRzog60gZLP9ex5Nrg.dJzkiRt1fn6','Diana Martinez','diana@example.com',NULL,0,0,0,1,0,'diana',NULL,NULL,0,1,NULL,'2025-11-15 22:49:06.918754','2025-11-15 22:49:06.918754',1,5,NULL),(6,'ethan','$2a$12$9K7/6ME2hRezvI1hg16.r..NPOQZKx46NM9Mt6cskYDfTPORKbERa','Ethan Brown','ethan@example.com',NULL,0,0,0,1,0,'ethan',NULL,NULL,0,1,NULL,'2025-11-15 22:49:07.130909','2025-11-15 22:49:07.130909',1,5,NULL),(7,'fiona','$2a$12$VbG2NF21lktaVQE3TdprbeF6y7hxBZMKeyGkZZSKxeQDvWIy/5I/u','Fiona Wilson','fiona@example.com',NULL,0,0,0,1,0,'fiona',NULL,NULL,0,1,NULL,'2025-11-15 22:49:07.352882','2025-11-15 22:49:07.352882',1,5,NULL),(8,'heike','$2a$12$YjZNcOlcQHP/fZZNy29P4OQiC1IX8q34ISe95q/uDgQWtsvR77Y2G','Blaine Graham','troy@moore.example',NULL,0,0,0,1,0,NULL,NULL,NULL,0,1,NULL,'2025-11-15 22:49:09.361012','2025-11-15 22:49:09.361012',1,3,NULL),(9,'jimmy_hartmann','$2a$12$ctzF5S5Oa7ln7.zqaQOE3uppVAukgqbZzr27z6/JnVpW37H8dYYRy','Rep. Laurena Ledner','mariel@howe.example',NULL,0,0,0,1,0,NULL,NULL,NULL,0,1,NULL,'2025-11-15 22:49:09.558354','2025-11-15 22:49:09.558354',1,3,NULL),(10,'breann_ohara','$2a$12$lQE59ews5RzQ8G/eGulW7uiYUXxf8V3Vd7c0AETVyLFSSr9D79.12','Agustin Feil','phung@hettinger-schultz.example',NULL,0,0,0,1,0,'simon-rohan',NULL,NULL,0,1,NULL,'2025-11-15 22:49:10.589466','2025-11-15 22:49:10.589466',1,5,NULL),(11,'nan','$2a$12$EzVoweoIZDrhIcqt3j9vp.lYK8NceLtYEvbqlP/zdPwlt1roGhgIe','Ricky Okuneva','joseph@lemke.example',NULL,0,0,0,1,0,'martine',NULL,NULL,0,1,NULL,'2025-11-15 22:49:10.790924','2025-11-15 22:49:10.790924',1,5,NULL),(12,'raymond_dibbert','$2a$12$MPj82l1s1ODjSq7bxoyODOVDteqOYNwBCymcnbSf5Uu4jyedIXAf2','Bret Moore','lakeesha_donnelly@armstrong-bogisich.example',NULL,0,0,0,1,0,'joanne-reichert',NULL,NULL,0,1,NULL,'2025-11-15 22:49:10.983761','2025-11-15 22:49:10.983761',1,5,NULL),(13,'marshall_block','$2a$12$jYJxb9V4I0qNY6hyNlfJ4e.G4cNYs1.4QzP.avwsSK3Tfq10lgSv6','Arthur Mertz','zack@lehner-nikolaus.test',NULL,0,0,0,1,0,'antonetta',NULL,NULL,0,1,NULL,'2025-11-15 22:49:11.196071','2025-11-15 22:49:11.196071',1,5,NULL),(14,'kirby_kihn','$2a$12$.KDaZzjPFA6t4htIBshql.iUqw4cBbRuvuJHcqk/XGKcw9W.fMbKu','Raymond Nolan','tobias.treutel@schuster-gutkowski.test',NULL,0,0,0,1,0,'glenda',NULL,NULL,0,1,NULL,'2025-11-15 22:49:11.402705','2025-11-15 22:49:11.402705',1,5,NULL),(15,'pablo_medhurst','$2a$12$Kw/yW8tdqM3tWd8mplQAZu.2ZO4dRBx2XrKX87qFcxEfuP3rmQ3qu','Logan Yundt','chang@funk-bergstrom.test',NULL,0,0,0,1,0,'kenda',NULL,NULL,0,1,NULL,'2025-11-15 22:49:11.605050','2025-11-15 22:49:11.605050',1,5,NULL),(16,'heather','$2a$12$Jsu8iL1Io1IxZgdvb9HqfeMpqzdqF56WewRPIBSSFs23oOSFlauh6','Sam Leannon','robin@white.example',NULL,0,0,0,1,0,'ji',NULL,NULL,0,1,NULL,'2025-11-15 22:49:11.805567','2025-11-15 22:49:11.805567',1,5,NULL),(17,'edie_hane','$2a$12$fsCbIXuTfWGoHygg2mR7Xu4mdk3TNHXLvcc/5MptYxXRpoAl2Us0q','Jeffry Kris','lawerence@bednar.example',NULL,0,0,0,1,0,'nelson',NULL,NULL,0,1,NULL,'2025-11-15 22:49:12.007642','2025-11-15 22:49:12.007642',1,5,NULL),(18,'rosenda_morar','$2a$12$hXK32BUXSHNmz1Co1A0jSe7V9harj5ZXMmC.ZCTbzCBKwI9J4wQma','Jackson Kautzer','reyes.stiedemann@lang.test',NULL,0,0,0,1,0,'xavier',NULL,NULL,0,1,NULL,'2025-11-15 22:49:12.214776','2025-11-15 22:49:12.214776',1,5,NULL),(19,'edison','$2a$12$2gBlIWdChpu5CRClWwrXKemFlGhKRh.9TEHyuF394cb7vVrMAaQ7C','Rep. Sheldon Miller','abe@okeefe-jacobs.test',NULL,0,0,0,1,0,'rose',NULL,NULL,0,1,NULL,'2025-11-15 22:49:12.443180','2025-11-15 22:49:12.443180',1,5,NULL),(20,'rebeca_metz','$2a$12$NIUY5o2NpuDCsbvLKLSaQ.WmGd4uoNGVvbvSkK3ljxnqDRaqluPsq','Mariel Hettinger','damien@kunde-corwin.test',NULL,0,0,0,1,0,'lissa-keeling',NULL,NULL,0,1,NULL,'2025-11-15 22:49:12.677076','2025-11-15 22:49:12.677076',1,5,NULL),(21,'francesco','$2a$12$Bt52GRFtVAitdE4UQnuug.Ui8zhujseb87V8V5eWlShGTq.FoOYPe','Thomasena Prohaska','danae.bosco@lakin.test',NULL,0,0,0,1,0,'jonathan-gulgowski',NULL,NULL,0,1,NULL,'2025-11-15 22:49:12.880843','2025-11-15 22:49:12.880843',1,5,NULL),(22,'jacob','$2a$12$ApRpl.N48d17smJW6cexJeIZEQ0SDAnfw6mtxyvt90mmsQcNCc6Ai','Benjamin Romaguera','marty@okon.test',NULL,0,0,0,1,0,'livia',NULL,NULL,0,1,NULL,'2025-11-15 22:49:13.091180','2025-11-15 22:49:13.091180',1,5,NULL),(23,'ivory_pouros','$2a$12$Fv1F3x70gpNij.JCU1M/q.T3ja5wQRe1hLclz4I3bwAOJ9VOd5uRW','Germaine Altenwerth','marlena.predovic@koelpin.test',NULL,0,0,0,1,0,'janiece',NULL,NULL,0,1,NULL,'2025-11-15 22:49:13.327186','2025-11-15 22:49:13.327186',1,5,NULL),(24,'seymour','$2a$12$L7gn/H7kcY7vVnjgL4gjxOJ3E7tgx/bFzImFIpP.MHYzDZwjY3eA.','Hugh Shields','hassan.labadie@cartwright-witting.example',NULL,0,0,0,1,0,'jason',NULL,NULL,0,1,NULL,'2025-11-15 22:49:13.538869','2025-11-15 22:49:13.538869',1,5,NULL),(25,'catherina','$2a$12$BxEJQFfBN2623ngTs4LplOBib12i1RqZ7xXeMzpNFQtGkPSfN.H3y','Jeremy Wisoky','andreas_schoen@harris.example',NULL,0,0,0,1,0,'michel-mohr',NULL,NULL,0,1,NULL,'2025-11-15 22:49:13.734944','2025-11-15 22:49:13.734944',1,5,NULL),(26,'damian','$2a$12$.K7krwTb7fjySi2vcXu6He8xG4ziRmLkl542qm9PxAX6IqvFJN9um','Norman Rodriguez','russel@lockman.test',NULL,0,0,0,1,0,'wesley',NULL,NULL,0,1,NULL,'2025-11-15 22:49:13.947616','2025-11-15 22:49:13.947616',1,5,NULL),(27,'lakita','$2a$12$OBaHESnqSiuqvbwNpB70ueRuS5k39QVHFgVlPZQVFX0Ao1v2NUfHK','Almeda Wuckert Sr.','miranda@cole-sauer.example',NULL,0,0,0,1,0,'eileen',NULL,NULL,0,1,NULL,'2025-11-15 22:49:14.148864','2025-11-15 22:49:14.148864',1,5,NULL),(28,'betsey_breitenberg','$2a$12$k.tYvUNLiZ/WhKT/8kirgeW9ZuVHagWmEG9HUZJ7v0AvBrMgNuy8q','Marc Wuckert','johnie@bahringer-quigley.example',NULL,0,0,0,1,0,'lynwood-medhurst',NULL,NULL,0,1,NULL,'2025-11-15 22:49:14.347485','2025-11-15 22:49:14.347485',1,5,NULL),(29,'aldo','$2a$12$UbpJC6KFTiusZbkp.m3rzecCdVeXlRQemiGETvEX..F.3GaA2xQkq','Connie Moen','timothy_little@kovacek.test',NULL,0,0,0,1,0,'ira',NULL,NULL,0,1,NULL,'2025-11-15 22:49:14.554583','2025-11-15 22:49:14.554583',1,5,NULL),(30,'fidela','$2a$12$GSxQRlm0/PZTTAeIq0ZHguDkzQgWO/9RYTLKU6wYFheO74HqWJi4e','Msgr. Tommie Daugherty','dion@abshire.test',NULL,0,0,0,1,0,'gavin',NULL,NULL,0,1,NULL,'2025-11-15 22:49:14.753713','2025-11-15 22:49:14.753713',1,5,NULL),(31,'stacy','$2a$12$C4G.3cw6bgJEoTBAhdCWvOMmO3W7cw7r05P.ZbbODMQe5ewo13aA2','Darby Zemlak','brett.feil@thompson-hintz.example',NULL,0,0,0,1,0,'anthony',NULL,NULL,0,1,NULL,'2025-11-15 22:49:14.969435','2025-11-15 22:49:14.969435',1,5,NULL),(32,'renna_mccullough','$2a$12$62D151j/MivNsCWO9A9Rf.C2o/Vtoz1cUoaNXlwNJ3EcVddKGnFx2','Cherri Casper','jamey.leffler@gleichner.example',NULL,0,0,0,1,0,'anthony-schuppe',NULL,NULL,0,1,NULL,'2025-11-15 22:49:15.166643','2025-11-15 22:49:15.166643',1,5,NULL),(33,'adaline_runte','$2a$12$otC42sAsD1BlQnLMqLuO7ep0kr2MELuZha2K.dlwrYnUWdLKx7So2','Clinton Wiegand','kiana_gleichner@stoltenberg.example',NULL,0,0,0,1,0,'julieann',NULL,NULL,0,1,NULL,'2025-11-15 22:49:15.375901','2025-11-15 22:49:15.375901',1,5,NULL),(34,'david','$2a$12$6wlBCKrtP6R9zOgVxyB71etafith2YOO0mUTNkmEw4hDSdJZgkG62','Wyatt Mueller II','shirl@mayer.test',NULL,0,0,0,1,0,'milton-sanford',NULL,NULL,0,1,NULL,'2025-11-15 22:49:15.583437','2025-11-15 22:49:15.583437',1,5,NULL),(35,'donald','$2a$12$JZv328TZMDJmn4zgzrEzdOFSC965H5xWBcpqirFIdvDK8F4l/RNCy','Nita Macejkovic','nathanial.hessel@anderson.test',NULL,0,0,0,1,0,'colin-stracke',NULL,NULL,0,1,NULL,'2025-11-15 22:49:15.795134','2025-11-15 22:49:15.795134',1,5,NULL),(36,'thad_schaden','$2a$12$j6G1ulQ8hbCziSvLkrGJ5.9B7pW7zVztromG5GPWkj3I4HOwlxvdy','Dr. Eldon Buckridge','nestor@turner-tremblay.example',NULL,0,0,0,1,0,'rigoberto-oberbrunner',NULL,NULL,0,1,NULL,'2025-11-15 22:49:15.995918','2025-11-15 22:49:15.995918',1,5,NULL),(37,'casey','$2a$12$wQDmK3GbvmzPLBdQXR3AqOHhPSrMpHwEMw3Nwl4rORMNdfbjn/XhS','Marketta Kirlin','bettie_smitham@stokes-baumbach.example',NULL,0,0,0,1,0,'vern-blick',NULL,NULL,0,1,NULL,'2025-11-15 22:49:16.198008','2025-11-15 22:49:16.198008',1,5,NULL),(38,'quinn','$2a$12$jsATc51esaAoyUCojko60O9QKWiv7ShhR2cxO6zU1b/FGpnNMZOlm','Muriel Koss','charley_bailey@rath.test',NULL,0,0,0,1,0,'janyce',NULL,NULL,0,1,NULL,'2025-11-15 22:49:16.406961','2025-11-15 22:49:16.406961',1,5,NULL),(39,'mackenzie','$2a$12$At9c0GCZyzF5eJ2ICHnWP.Y5wVNoIx4C7HroSDxeGX7m5cvaspLom','Tamatha Gorczany','shea_hyatt@ward.test',NULL,0,0,0,1,0,'kerrie-hane',NULL,NULL,0,1,NULL,'2025-11-15 22:49:16.616785','2025-11-15 22:49:16.616785',1,5,NULL),(40,'shirley','$2a$12$t/l9CAjNlTcxIA96/sQIjeneMNTEaXjvivkx9Puyg87nAI74sv8dq','Selma Dooley','clarine@medhurst-ritchie.example',NULL,0,0,0,1,0,'jerald',NULL,NULL,0,1,NULL,'2025-11-15 22:49:16.821363','2025-11-15 22:49:16.821363',1,5,NULL),(41,'terisa','$2a$12$5zaSPlcP3554kNNzwZQoKezBq0ydUKUfthjZMfTLOmPxVSbG9q6qS','Season Abshire','burton.farrell@quitzon.test',NULL,0,0,0,1,0,'kylie-beier',NULL,NULL,0,1,NULL,'2025-11-15 22:49:17.025014','2025-11-15 22:49:17.025014',1,5,NULL),(42,'suzan','$2a$12$5BOJwKQL0zjo9QGZXXQwse.qzgz4l0vNhaWC8bmRw7GYvdXrZO5pO','Rhett Collier','palmer.gibson@stiedemann.example',NULL,0,0,0,1,0,'willian-hirthe',NULL,NULL,0,1,NULL,'2025-11-15 22:49:17.230537','2025-11-15 22:49:17.230537',1,5,NULL),(43,'tony_schuppe','$2a$12$kIJNqs7mT8IO.jlhMjB6HOOOxlRh89luvUjSHRExHSANerEBd5TvS','Evalyn Runte','claudette.homenick@renner.example',NULL,0,0,0,1,0,'vincent',NULL,NULL,0,1,NULL,'2025-11-15 22:49:17.432953','2025-11-15 22:49:17.432953',1,5,NULL),(44,'terrell','$2a$12$YzXdI5kEFDJ1mOOJonN9ze9UjRvOXOnd6CEfNNp2upsPf2KXR8Bhu','Brock O\'Keefe III','marilee@hilpert.test',NULL,0,0,0,1,0,'kayla',NULL,NULL,0,1,NULL,'2025-11-15 22:49:17.641109','2025-11-15 22:49:17.641109',1,5,NULL),(45,'dwana_macgyver','$2a$12$9FyYFTTEsukbX0iW/HFEEe9P5eVJHJmc6sew6m.O6VvGcK6CdYov.','Hyon Thiel','morris.herman@block-stehr.test',NULL,0,0,0,1,0,'hung',NULL,NULL,0,1,NULL,'2025-11-15 22:49:17.835641','2025-11-15 22:49:17.835641',1,5,NULL),(46,'mckinley','$2a$12$240kAcLb/X5/uSFgf6Lol.LsB/dmc8eGoaOOwQoEIZ1htxovP0PAe','Ms. Aurelio Deckow','cassaundra@gislason.test',NULL,0,0,0,1,0,'ermelinda-mills',NULL,NULL,0,1,NULL,'2025-11-15 22:49:18.030227','2025-11-15 22:49:18.030227',1,5,NULL),(47,'keeley','$2a$12$UPRIALtJ.wUIKqVyOOxWw.OO9.OjmvyoVAHeeDG8mNrW/h9chy16.','Liane Kohler Esq.','marybeth_stanton@sawayn.test',NULL,0,0,0,1,0,'whitney',NULL,NULL,0,1,NULL,'2025-11-15 22:49:18.243797','2025-11-15 22:49:18.243797',1,5,NULL),(48,'milford_brekke','$2a$12$Nf1BBymrusDIAEJD4WAtaue0obrcYRM.3n6SOb4Jisr0YEIbVdeLu','Vern Stehr','twyla.prohaska@leuschke-stehr.test',NULL,0,0,0,1,0,'sergio',NULL,NULL,0,1,NULL,'2025-11-15 22:49:18.464760','2025-11-15 22:49:18.464760',1,5,NULL),(49,'lupe_west','$2a$12$S.eRInToSH7Bee9YZkIkueR108wIk6u9WnbNzBbCtOMaqN7Tknmhq','Alfred White','marcelino@cruickshank.test',NULL,0,0,0,1,0,'stanford',NULL,NULL,0,1,NULL,'2025-11-15 22:49:18.674721','2025-11-15 22:49:18.674721',1,5,NULL),(50,'audria','$2a$12$CaymNcMEvNRlIrh5i3fXkOoUa/A2k8IJEpfya2G4BavKYBQERXRHq','Rosario Raynor','lashunda@adams-runolfsson.test',NULL,0,0,0,1,0,'margene',NULL,NULL,0,1,NULL,'2025-11-15 22:49:18.878725','2025-11-15 22:49:18.878725',1,5,NULL),(51,'mallie','$2a$12$Yhd7UMfiQByNd8befS3lL.WvIzbKJUJf31i3SKDpGF.vSp2mhvXGC','Dean Carroll','tamatha.macejkovic@williamson-schuster.test',NULL,0,0,0,1,0,'wanda-oreilly',NULL,NULL,0,1,NULL,'2025-11-15 22:49:19.089954','2025-11-15 22:49:19.089954',1,5,NULL),(52,'sharda','$2a$12$QREH39TpuZ.vX11HlskHXOA02wyWKLuLGNzV1MiwRFXjHfbaAHd2G','Hang Cormier DC','elvera@brown-wilderman.test',NULL,0,0,0,1,0,'james',NULL,NULL,0,1,NULL,'2025-11-15 22:49:19.293444','2025-11-15 22:49:19.293444',1,5,NULL),(53,'francisco_mills','$2a$12$NmvdYgWqHxVc/KiU1b260eRDT4HJc9MJ4vx5AQRA/BsCqbPMOi9Nq','Kai Jerde DC','karl.ziemann@mitchell.example',NULL,0,0,0,1,0,'gregory',NULL,NULL,0,1,NULL,'2025-11-15 22:49:19.491197','2025-11-15 22:49:19.491197',1,5,NULL),(54,'jeromy_schaden','$2a$12$J/Vr1ei/AQZdXRVL68ED.uqZqM7yHeIQIVtDkzg9S3Yxpob1fycJu','Wilson Lehner','sam@collier.test',NULL,0,0,0,1,0,'johnie-zemlak',NULL,NULL,0,1,NULL,'2025-11-15 22:49:19.694554','2025-11-15 22:49:19.694554',1,5,NULL),(55,'kizzy','$2a$12$acIqqMmYyUPnMJd0OU6Ck.ItrwH5Q9I2ZkCMhASxZ8.neA.kD.L/S','Malcolm Doyle','douglass.kshlerin@reilly-breitenberg.test',NULL,0,0,0,1,0,'erline',NULL,NULL,0,1,NULL,'2025-11-15 22:49:19.895422','2025-11-15 22:49:19.895422',1,5,NULL);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-11-15 23:30:17
