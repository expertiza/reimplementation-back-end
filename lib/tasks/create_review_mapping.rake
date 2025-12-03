# frozen_string_literal: true

namespace :dev do
  desc 'Create a ReviewResponseMap with a submitted Response and Answers for manual testing'
  task create_review_mapping: :environment do
    ActiveRecord::Base.transaction do
      puts 'Starting create_review_mapping task'

      # Find or create a minimal assignment
      assignment = Assignment.first
      unless assignment
        instructor = User.find_by(role_id: 3) || User.find_by(role_id: 1)
        course = Course.first || Course.create!(instructor_id: (instructor&.id || 1), institution_id: 1, directory_path: 'seed/course', name: 'Seed Course', info: 'Auto created by rake task', private: false)
        instructor_id = instructor&.id || User.first&.id || 1
        assignment = Assignment.create!(name: 'Seed Assignment', instructor_id: instructor_id, course_id: course.id, has_teams: true, private: false)
        puts "Created Assignment id=#{assignment.id}"
      else
        puts "Using existing Assignment id=#{assignment.id}"
      end

      # Create or find a questionnaire
      instructor_for_q = User.find_by(role_id: 1) || User.find_by(role_id: 3) || User.first
      questionnaire = Questionnaire.find_by(name: 'Seed Review Questionnaire')
      unless questionnaire
        questionnaire = Questionnaire.create!(name: 'Seed Review Questionnaire', instructor_id: instructor_for_q.id, min_question_score: 0, max_question_score: 5, questionnaire_type: 'Review')
        puts "Created Questionnaire id=#{questionnaire.id}"
      else
        puts "Using Questionnaire id=#{questionnaire.id}"
      end

      # Create two items/questions for the questionnaire if none exist
      if questionnaire.items.empty?
        2.times do |i|
          attrs = {
            questionnaire_id: questionnaire.id,
            txt: "Criterion #{i + 1}",
            question_type: 'Scale',
            weight: 1,
            break_before: true,
            seq: i + 1,
            size: '50,3'
          }

          begin
            Item.find_or_create_by!(questionnaire_id: questionnaire.id, seq: attrs[:seq]) do |it|
              it.txt = attrs[:txt]
              it.question_type = attrs[:question_type]
              it.weight = attrs[:weight]
              it.break_before = attrs[:break_before]
              it.size = attrs[:size]
            end
          rescue ActiveRecord::RecordInvalid => e
            puts "Failed to create Item with attrs=#{attrs.inspect}: #{e.record.errors.full_messages.join(', ')}"
            # Try fallback with minimal safe values
            fallback = attrs.merge(break_before: true, seq: i + 1)
            Item.create!(fallback)
          end
        end
        puts "Created #{questionnaire.items.count} items for Questionnaire id=#{questionnaire.id}"
      else
        puts "Questionnaire already has #{questionnaire.items.count} items"
      end

      # Link assignment and questionnaire (used_in_round = 1)
      aq = AssignmentQuestionnaire.find_or_create_by!(assignment_id: assignment.id, questionnaire_id: questionnaire.id) do |a|
        a.used_in_round = 1
        a.notification_limit = 5.0
      end
      puts "AssignmentQuestionnaire id=#{aq.id} (assignment=#{assignment.id}, questionnaire=#{questionnaire.id})"

      # Create a team for the assignment
      team = AssignmentTeam.where(parent_id: assignment.id).first
      unless team
        team = AssignmentTeam.create!(name: 'Seed Team', parent_id: assignment.id)
        puts "Created AssignmentTeam id=#{team.id}"
      else
        puts "Using existing AssignmentTeam id=#{team.id}"
      end

      # Create a reviewer user and participant
      reviewer_user = User.where(role_id: 5).first
      unless reviewer_user
        reviewer_user = User.create!(name: 'seed_reviewer', email: "seed_reviewer_#{Time.now.to_i}@example.com", password: 'password', full_name: 'Seed Reviewer', institution_id: 1, role_id: 5)
        puts "Created reviewer User id=#{reviewer_user.id}"
      else
        puts "Using existing reviewer User id=#{reviewer_user.id}"
      end

      reviewer_participant = AssignmentParticipant.where(user_id: reviewer_user.id, parent_id: assignment.id).first
      unless reviewer_participant
        reviewer_handle = reviewer_user.respond_to?(:handle) && reviewer_user.handle.present? ? reviewer_user.handle : reviewer_user.name
        reviewer_participant = AssignmentParticipant.create!(user_id: reviewer_user.id, parent_id: assignment.id, team_id: team.id, handle: reviewer_handle)
        puts "Created AssignmentParticipant (reviewer) id=#{reviewer_participant.id}"
      else
        # ensure existing participant has handle
        unless reviewer_participant.handle.present?
          reviewer_participant.handle = reviewer_user.respond_to?(:handle) && reviewer_user.handle.present? ? reviewer_user.handle : reviewer_user.name
          reviewer_participant.save!
        end
        puts "Using existing AssignmentParticipant (reviewer) id=#{reviewer_participant.id}"
      end

      # Ensure the team has at least one member (a student participant)
      team_member_user = User.where(role_id: 5).where.not(id: reviewer_user.id).first
      unless team_member_user
        team_member_user = User.create!(name: 'seed_team_user', email: "seed_team_user_#{Time.now.to_i}@example.com", password: 'password', full_name: 'Seed Team Member', institution_id: 1, role_id: 5)
        puts "Created team member user id=#{team_member_user.id}"
      else
        puts "Using team member user id=#{team_member_user.id}"
      end

      team_member_participant = AssignmentParticipant.where(user_id: team_member_user.id, parent_id: assignment.id).first
      unless team_member_participant
        member_handle = team_member_user.respond_to?(:handle) && team_member_user.handle.present? ? team_member_user.handle : team_member_user.name
        team_member_participant = AssignmentParticipant.create!(user_id: team_member_user.id, parent_id: assignment.id, team_id: team.id, handle: member_handle)
        puts "Created AssignmentParticipant (team member) id=#{team_member_participant.id}"
      else
        unless team_member_participant.handle.present?
          team_member_participant.handle = team_member_user.respond_to?(:handle) && team_member_user.handle.present? ? team_member_user.handle : team_member_user.name
          team_member_participant.save!
        end
        puts "Using existing AssignmentParticipant (team member) id=#{team_member_participant.id}"
      end

      # Create the ReviewResponseMap linking reviewer participant to the team
      map = ReviewResponseMap.where(reviewee_id: team.id, reviewer_id: reviewer_participant.id, reviewed_object_id: assignment.id).first
      unless map
        # ReviewResponseMap does not accept team_reviewing_enabled as an attribute
        map = ReviewResponseMap.create!(reviewee_id: team.id, reviewer_id: reviewer_participant.id, reviewed_object_id: assignment.id)
        puts "Created ReviewResponseMap id=#{map.id}"
      else
        puts "Using existing ReviewResponseMap id=#{map.id}"
      end

      # Create a submitted Response for the map
      response = map.responses.where(round: 1).last
      unless response
        response = Response.create!(map_id: map.id, round: 1, is_submitted: true)
        puts "Created Response id=#{response.id} (map_id=#{map.id})"

        # Create answers for each item in the questionnaire
        questionnaire.items.each_with_index do |item, idx|
          Answer.create!(response_id: response.id, item_id: item.id, answer: (item.weight || 1) * 4, comments: "Auto-generated answer #{idx + 1}")
        end
        puts "Created #{response.scores.count} answers for Response id=#{response.id}"
      else
        puts "Using existing Response id=#{response.id} for map_id=#{map.id}"
      end

      # --- NEW: create teammate review mappings and responses to populate participant-level scores ---
      # We'll ensure the team_member_participant (a student on the team) has both reviews_by_me and reviews_of_me
      begin
        # teammate review where reviewer = reviewer_participant, reviewee = team_member_participant
        teammate_map_1 = TeammateReviewResponseMap.where(reviewed_object_id: assignment.id, reviewer_id: reviewer_participant.id, reviewee_id: team_member_participant.id).first
        unless teammate_map_1
          teammate_map_1 = TeammateReviewResponseMap.create!(reviewed_object_id: assignment.id, reviewer_id: reviewer_participant.id, reviewee_id: team_member_participant.id)
          puts "Created TeammateReviewResponseMap id=#{teammate_map_1.id} (reviewer=#{reviewer_participant.id} -> reviewee=#{team_member_participant.id})"
        else
          puts "Using existing TeammateReviewResponseMap id=#{teammate_map_1.id}"
        end

        response_tm_1 = teammate_map_1.responses.where(round: 1).last
        unless response_tm_1
          response_tm_1 = Response.create!(map_id: teammate_map_1.id, round: 1, is_submitted: true)
          questionnaire.items.each_with_index do |item, idx|
            Answer.create!(response_id: response_tm_1.id, item_id: item.id, answer: (item.weight || 1) * 3, comments: "Auto-generated teammate answer #{idx + 1}")
          end
          puts "Created #{response_tm_1.scores.count} answers for Teammate Response id=#{response_tm_1.id}"
        else
          puts "Using existing Teammate Response id=#{response_tm_1.id} for map_id=#{teammate_map_1.id}"
        end

        # teammate review where reviewer = team_member_participant, reviewee = reviewer_participant (so the student also reviewed someone)
        teammate_map_2 = TeammateReviewResponseMap.where(reviewed_object_id: assignment.id, reviewer_id: team_member_participant.id, reviewee_id: reviewer_participant.id).first
        unless teammate_map_2
          teammate_map_2 = TeammateReviewResponseMap.create!(reviewed_object_id: assignment.id, reviewer_id: team_member_participant.id, reviewee_id: reviewer_participant.id)
          puts "Created TeammateReviewResponseMap id=#{teammate_map_2.id} (reviewer=#{team_member_participant.id} -> reviewee=#{reviewer_participant.id})"
        else
          puts "Using existing TeammateReviewResponseMap id=#{teammate_map_2.id}"
        end

        response_tm_2 = teammate_map_2.responses.where(round: 1).last
        unless response_tm_2
          response_tm_2 = Response.create!(map_id: teammate_map_2.id, round: 1, is_submitted: true)
          questionnaire.items.each_with_index do |item, idx|
            Answer.create!(response_id: response_tm_2.id, item_id: item.id, answer: (item.weight || 1) * 5, comments: "Auto-generated teammate answer #{idx + 1}")
          end
          puts "Created #{response_tm_2.scores.count} answers for Teammate Response id=#{response_tm_2.id}"
        else
          puts "Using existing Teammate Response id=#{response_tm_2.id} for map_id=#{teammate_map_2.id}"
        end
      rescue StandardError => e
        puts "Failed to create teammate maps/responses: #{e.class} - #{e.message}"
        puts e.backtrace.join("\n")
      end

      puts 'create_review_mapping task completed successfully.'
      puts "map_id=#{map.id}, response_id=#{response.id}"
    end
  rescue StandardError => e
    puts "Failed to create review mapping: #{e.class} - #{e.message}"
    puts e.backtrace.join("\n")
    raise e
  end
end
