# frozen_string_literal: true

module ExpertizaConstants
  module DeadlineTypes
    SUBMISSION       = 1
    REVIEW           = 2
    QUIZ             = 6
    DROP_TOPIC       = 7
    SIGNUP           = 8
    TEAM_FORMATION   = 9

    # Maps deadline_type_id to stage name, mirroring the old DeadlineType table
    NAMES = {
      SUBMISSION => 'submission',
      REVIEW => 'review',
      QUIZ => 'quiz',
      DROP_TOPIC => 'drop_topic',
      SIGNUP => 'signup',
      TEAM_FORMATION => 'team_formation'
    }.freeze
  end

  module ResponseMapTitles
    ASSIGNMENT_SURVEY_RESPONSE_MAP_TITLE = 'Assignment Survey'
    BOOKMARK_RATING_RESPONSE_MAP_TITLE = 'Bookmark Review'
    COURSE_SURVEY_RESPONSE_MAP_TITLE = 'Course Survey'
    FEEDBACK_RESPONSE_MAP_TITLE = 'Feedback'
    GLOBAL_SURVEY_RESPONSE_MAP_TITLE = 'Global Survey'
    METAREVIEW_RESPONSE_MAP_TITLE = 'Metareview'
    QUIZ_RESPONSE_MAP_TITLE = 'Quiz'
    REVIEW_RESPONSE_MAP_TITLE = 'Review'
    SURVEY_RESPONSE_MAP_TITLE = 'Survey'
    TEAMMATE_REVIEW_RESPONSE_MAP_TITLE = 'Teammate Review'
  end
end
