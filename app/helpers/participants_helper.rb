module ParticipantsHelper
  # ===========================================================
  # A participant can be one of the following authorizations:
  # Reader
  # Reviewer
  # Submitter
  # Mentor
  # ===========================================================
  # Grant a participant permissions to submit, review,
  # take quizzes, and mentor based on their authorization
  def retrieve_participant_permissions(authorization)
    default_permissions = {
      can_submit: true,
      can_review: true,
      can_take_quiz: true,
      can_mentor: false
    }

    permissions_map = {
      'reader' => { can_submit: false },
      'reviewer' => { can_submit: false, can_take_quiz: false },
      'submitter' => { can_review: false, can_take_quiz: false },
      'mentor' => { can_mentor: true }
    }

    default_permissions.merge(permissions_map[authorization])
  end
end
