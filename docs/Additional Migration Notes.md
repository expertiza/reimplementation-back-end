In the migrated db, a duty rubric is specified in assignments_duties.
- This suggests that the same rubric can be used for different duties in different assignments.
- But it’s very unlikely that anyone would use the same questionnaire for different duties, so it makes more sense to add a duty field to a questionnaire, specifying the duty that it will be used for when that questionnaire is used in an assignment.
- Then assignments_questionnaires would not need to specify the duty, because that could be read from the questionnaire.
