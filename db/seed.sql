USE reimplementation_development;

DROP TABLE IF EXISTS `questionnaires`;

CREATE TABLE `questionnaires` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(64) DEFAULT NULL,
  `instructor_id` int(11) NOT NULL DEFAULT '0',
  `private` tinyint(1) NOT NULL DEFAULT '0',
  `min_question_score` int(11) NOT NULL DEFAULT '0',
  `max_question_score` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `type` varchar(255) DEFAULT NULL,
  `display_type` varchar(255) DEFAULT NULL,
  `instruction_loc` text,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=717 DEFAULT CHARSET=latin1;

LOCK TABLES `questionnaires` WRITE;

INSERT INTO `questionnaires` VALUES (1,'rubric1',2,0,1,5,NULL,'2009-12-16 13:05:11','ReviewQuestionnaire','Review',NULL),
(4,'ethical_analysis_wiki',6,0,0,5,NULL,'2009-12-16 13:05:11','ReviewQuestionnaire','Review',NULL),
(5,'Ethics research project',6,0,0,5,NULL,'2009-12-16 13:05:11','ReviewQuestionnaire','Review',NULL),
(6,'Sample Quiz',6,0,0,5,NULL,'2009-12-16 13:05:11','QuizQuestionnaire','Quiz',NULL);

UNLOCK TABLES;

DROP TABLE IF EXISTS `questions`;

CREATE TABLE `questions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `txt` text,
  `weight` int(11) DEFAULT NULL,
  `questionnaire_id` int(11) DEFAULT NULL,
  `seq` decimal(6,2) DEFAULT NULL,
  `type` varchar(255) DEFAULT NULL,
  `size` varchar(255) DEFAULT '',
  `alternatives` varchar(255) DEFAULT NULL,
  `break_before` tinyint(1) DEFAULT '1',
  `max_label` varchar(255) DEFAULT '',
  `min_label` varchar(255) DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `fk_question_questionnaires` (`questionnaire_id`),
  CONSTRAINT `fk_question_questionnaires` FOREIGN KEY (`questionnaire_id`) REFERENCES `questionnaires` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7909 DEFAULT CHARSET=latin1;

LOCK TABLES `questions` WRITE;

INSERT INTO `questions` VALUES (1,'This is my first question.',1,1,1.00,'Criterion',NULL,NULL,1,NULL,NULL),
(2,'This is my true/false question',1,1,2.00,'Checkbox',NULL,NULL,1,NULL,NULL),
(3,'This is my last question.',1,1,3.00,'Criterion',NULL,NULL,1,NULL,NULL),
(4,'This is my very last question',1,4,4.00,'Criterion',NULL,NULL,1,NULL,NULL),
(5,'Do the page(s) stick to the topic?',1,4,5.00,'Criterion',NULL,NULL,1,NULL,NULL),
(6,'Are there an appropriate number of links to outside sources?',1,4,6.00,'Criterion',NULL,NULL,1,NULL,NULL),
(7,'Does the analysis clearly identify the ethical issues?',1,5,7.00,'Criterion',NULL,NULL,1,NULL,NULL),
(8,'Do the page(s) treat differing viewpoints fairly?',1,5,8.00,'Criterion',NULL,NULL,1,NULL,NULL),
(9,'Is the organization of page(s) logical?',1,5,9.00,'Criterion',NULL,NULL,1,NULL,NULL),
(10,'Do the page(s) identify several issues that are important in learning about the topic?',1,6,10.00,'Criterion',NULL,NULL,1,NULL,NULL),
(11,'Do the study guide and the Table of Contents page clearly identify the ethical issues?',1,6,11.00,'Criterion',NULL,NULL,1,NULL,NULL),
(12,'Do study guide and the Table of Contents treat differing viewpoints fairly?',1,6,12.00,'Criterion',NULL,NULL,1,NULL,NULL);

UNLOCK TABLES;

