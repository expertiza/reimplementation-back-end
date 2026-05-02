# frozen_string_literal: true

namespace :demo do
  desc 'Create or refresh calibration report demo data with six student results'
  task calibration_report: :environment do
    role_for = lambda do |name|
      Role.find_by!(name: name)
    end

    institution = Institution.first || Institution.create!(name: 'North Carolina State University')

    ensure_user = lambda do |model_class:, name:, email:, role_name:, full_name:, password: 'password123', parent: nil|
      user = User.find_by(name: name) || User.find_by(email: email)

      if user
        user.update!(
          email: email,
          full_name: full_name,
          role: role_for.call(role_name),
          institution: institution,
          parent: parent
        )
        user.password = password if user.authenticate(password).nil?
        user.save! if user.changed?
        model_class.find(user.id)
      else
        model_class.create!(
          name: name,
          email: email,
          password: password,
          full_name: full_name,
          role: role_for.call(role_name),
          institution: institution,
          parent: parent
        )
      end
    end

    ensure_participant = lambda do |assignment:, user:, handle:|
      AssignmentParticipant.find_or_create_by!(parent_id: assignment.id, user_id: user.id) do |participant|
        participant.handle = handle
      end
    end

    ensure_item = lambda do |questionnaire:, txt:, seq:|
      item = questionnaire.items.find_or_initialize_by(txt: txt)
      item.assign_attributes(
        seq: seq,
        weight: 1,
        question_type: 'Scale',
        break_before: true
      )
      item.save!
      item
    end

    update_response = lambda do |map:, scores:|
      response = Response.where(map_id: map.id, is_submitted: true).order(updated_at: :desc).first

      unless response
        response = Response.create!(
          response_map: map,
          round: 1,
          version_num: Response.where(map_id: map.id).maximum(:version_num).to_i + 1,
          is_submitted: true
        )
      end

      response.update!(is_submitted: true, updated_at: Time.current)

      scores.each do |item, score|
        answer = Answer.find_or_initialize_by(response_id: response.id, item_id: item.id)
        answer.update!(
          answer: score,
          comments: ''
        )
      end

      response
    end

    instructor = ensure_user.call(
      model_class: Instructor,
      name: 'calibration_demo_instructor',
      email: 'calibration_demo_instructor@example.com',
      role_name: 'Instructor',
      full_name: 'Calibration Demo Instructor'
    )

    assignment = Assignment.find_by(id: 8) || Assignment.find_by(name: 'Calibration Demo Assignment')
    assignment ||= Assignment.create!(
      name: 'Calibration Demo Assignment',
      instructor: instructor,
      has_teams: true,
      private: false
    )
    assignment.update!(instructor: instructor, has_teams: true, private: false)

    reviewee_team =
      if assignment.id == 8 && ReviewResponseMap.exists?(id: 8, reviewed_object_id: assignment.id, for_calibration: true)
        ReviewResponseMap.find(8).reviewee
      else
        assignment.teams.find_or_create_by!(name: 'Calibration Demo Reviewee Team')
      end

    questionnaire =
      assignment.assignment_questionnaires.find_by(used_in_round: 1)&.questionnaire ||
      Questionnaire.find_by(name: 'Calibration Demo Rubric', instructor_id: instructor.id)

    questionnaire ||= Questionnaire.create!(
      name: 'Calibration Demo Rubric',
      private: false,
      min_question_score: 0,
      max_question_score: 5,
      instructor: instructor
    )

    AssignmentQuestionnaire.find_or_create_by!(
      assignment: assignment,
      questionnaire: questionnaire,
      used_in_round: 1
    )

    items = [
      ensure_item.call(questionnaire: questionnaire, txt: 'Code quality', seq: 1),
      ensure_item.call(questionnaire: questionnaire, txt: 'Documentation', seq: 2),
      ensure_item.call(questionnaire: questionnaire, txt: 'Testing', seq: 3)
    ]

    instructor_participant = ensure_participant.call(
      assignment: assignment,
      user: instructor,
      handle: instructor.name
    )

    instructor_map =
      ReviewResponseMap.find_by(id: 8, reviewed_object_id: assignment.id, for_calibration: true) ||
      ReviewResponseMap.find_or_create_by!(
        reviewed_object_id: assignment.id,
        reviewer_id: instructor_participant.id,
        reviewee_id: reviewee_team.id,
        for_calibration: true
      )

    update_response.call(
      map: instructor_map,
      scores: {
        items[0] => 4,
        items[1] => 5,
        items[2] => 3
      }
    )

    score_sets = [
      [4, 5, 3],
      [4, 4, 3],
      [4, 4, 2],
      [3, 4, 1],
      [3, 2, 1],
      [1, 1, 0]
    ]

    student_maps = score_sets.each_with_index.map do |scores, index|
      student = ensure_user.call(
        model_class: User,
        name: "calibration_demo_student_#{index + 1}",
        email: "calibration_demo_student_#{index + 1}@example.com",
        role_name: 'Student',
        full_name: "Calibration Demo Student #{index + 1}",
        parent: instructor
      )

      participant = ensure_participant.call(
        assignment: assignment,
        user: student,
        handle: student.name
      )

      map = ReviewResponseMap.find_or_create_by!(
        reviewed_object_id: assignment.id,
        reviewer_id: participant.id,
        reviewee_id: reviewee_team.id,
        for_calibration: true
      )

      update_response.call(
        map: map,
        scores: {
          items[0] => scores[0],
          items[1] => scores[1],
          items[2] => scores[2]
        }
      )

      map
    end

    ReviewResponseMap.where(
      reviewed_object_id: assignment.id,
      reviewee_id: reviewee_team.id,
      for_calibration: true
    ).where.not(id: [instructor_map.id, *student_maps.map(&:id)]).find_each(&:destroy!)

    reviewee_team.update!(submitted_hyperlinks: YAML.dump(['https://example.com/submission']))
    SubmissionRecord.find_or_create_by!(
      record_type: 'file',
      content: 'submission/report.pdf',
      operation: 'Submit File',
      team_id: reviewee_team.id,
      user: instructor.name,
      assignment_id: assignment.id
    )

    student_responses = student_maps.map do |map|
      Response.where(map_id: map.id, is_submitted: true).order(updated_at: :desc).first
    end
    instructor_response = Response.where(map_id: instructor_map.id, is_submitted: true).order(updated_at: :desc).first

    summaries = CalibrationPerItemSummary.build(
      items: items,
      instructor_response: instructor_response,
      student_responses: student_responses
    )

    distribution = summaries.map do |summary|
      {
        item: summary[:item_label],
        agree: summary[:bucket_counts][summary[:instructor_score].to_s],
        near: summary[:bucket_counts].select { |score, _count| (score.to_i - summary[:instructor_score].to_i).abs == 1 }.values.sum,
        disagree: summary[:bucket_counts].select { |score, _count| (score.to_i - summary[:instructor_score].to_i).abs > 1 }.values.sum
      }
    end

    puts({
      assignment_id: assignment.id,
      map_id: instructor_map.id,
      reviewee_id: reviewee_team.id,
      student_count: student_maps.length,
      rubric_items: items.map(&:txt),
      summaries: distribution,
      frontend_url: "http://localhost:3000/assignments/edit/#{assignment.id}/calibration/#{instructor_map.id}"
    }.inspect)
  end
end
