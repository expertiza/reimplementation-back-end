# frozen_string_literal: true

module Reports
  # Answer-tagging report: shows per-user tagging progress for each
  # TagPromptDeployment on the assignment, plus a cross-deployment summary.
  #
  # Output shape:
  #   {
  #     questionnaire_tagging_report: {
  #       <deployment_id> => {
  #         questionnaire_name:, prompt:, question_type:,
  #         answer_length_threshold:,
  #         user_stats: [{ user_id:, name:, full_name:, percentage:,
  #                        cnt_tagged:, cnt_not_tagged:, cnt_taggable:,
  #                        tag_update_intervals: }]
  #       }
  #     },
  #     user_tagging_report: {
  #       <user_id> => { user_id:, name:, full_name:, percentage:,
  #                      cnt_tagged:, cnt_not_tagged:, cnt_taggable: }
  #     }
  #   }
  class AnswerTaggingReport
    def self.for_assignment(assignment)
      new(assignment)
    end

    def initialize(assignment)
      @reportable = assignment
    end

    def run
      per_deployment = {}
      # The coordinator runs one DeploymentReducer per TagPromptDeployment,
      # then passes the results to UserSummaryReducer for cross-deployment totals.
      TagPromptDeployment
        .where(assignment_id: @reportable.id)
        .includes(:tag_prompt, :questionnaire)
        .each do |deployment|
          per_deployment[deployment.id] = DeploymentReducer.new(@reportable, deployment).run
        end
      user_summary = UserSummaryReducer.new(per_deployment).run
      {
        questionnaire_tagging_report: per_deployment,
        user_tagging_report:          user_summary
      }
    end

    # -------------------------------------------------------------------------
    # Coordinator — runs two streaming reducers for one TagPromptDeployment
    # and merges their results:
    #
    #   TaggableAnswersReducer — streams taggable Answer rows (joined with
    #     response_maps, filtered by item type and threshold). Returns per-user
    #     lists of taggable answer_ids.
    #     Output: { user_id => [answer_ids] }
    #
    #   TaggingStatsReducer — streams all AnswerTag rows for this deployment
    #     (joined with answers to get answer_id). No item/threshold filtering
    #     in SQL — filtering happens in finalize by comparing answer_ids.
    #     Output: { user_id => [{ answer_id:, response_id:, updated_at: }] }
    #
    # Precomputed once, shared across both reducers:
    #   @item_ids      — IDs of items in the deployment's questionnaire (tiny)
    #   @users_by_team — TeamsUser records grouped by team_id; also used in
    #                    finalize to build per-user name info
    # -------------------------------------------------------------------------
    class DeploymentReducer
      def initialize(reportable, deployment)
        @reportable    = reportable
        @deployment    = deployment
        @item_ids      = Item.for_questionnaire_and_type(deployment.questionnaire_id, deployment.question_type).pluck(:id)
        @users_by_team = TeamsUser.for_assignment(deployment.assignment_id).includes(:user).group_by(&:team_id)
      end

      def run
        taggable_data = TaggableAnswersReducer.new(@reportable, @deployment, @item_ids, @users_by_team).run
        tagging_stats = TaggingStatsReducer.new(@reportable, @deployment).run
        finalize(taggable_data, tagging_stats)
      end

      private

      def finalize(taggable_data, tagging_stats)
        user_info = @users_by_team.values.flatten.each_with_object({}) do |teams_user, info|
          info[teams_user.user_id] = { name: teams_user.user.name, full_name: teams_user.user.full_name }
        end

        user_stats = user_info.map do |user_id, info|
          taggable_answer_ids = taggable_data.fetch(user_id, []).to_set
          cnt_taggable        = taggable_answer_ids.size

          # Filter tags to only those on answers that are taggable for this user.
          # TODO: confirm with prof — if a reviewer submits multiple responses for the
          # same round, only the latest submitted response should be counted as taggable.
          # TaggableAnswersReducer may need to deduplicate by keeping only the most
          # recently submitted response per (reviewer, round).
          matching_tags  = tagging_stats.fetch(user_id, []).select { |tag| taggable_answer_ids.include?(tag[:answer_id]) }
          cnt_tagged     = matching_tags.size
          cnt_not_tagged = cnt_taggable - cnt_tagged

          tag_times_in_order     = matching_tags.map { |tag| tag[:updated_at] }.sort
          intervals_between_tags = tag_times_in_order.each_cons(2).map { |earlier, later| later - earlier }

          {
            user_id:              user_id,
            name:                 info[:name],
            full_name:            info[:full_name],
            percentage:           cnt_taggable.zero? ? '0.0' : format('%.1f', cnt_tagged.to_f / cnt_taggable * 100),
            cnt_tagged:           cnt_tagged,
            cnt_not_tagged:       cnt_not_tagged,
            cnt_taggable:         cnt_taggable,
            tag_update_intervals: intervals_between_tags
          }
        end

        {
          questionnaire_name:      @deployment.questionnaire.name,
          prompt:                  @deployment.tag_prompt.prompt,
          question_type:           @deployment.question_type,
          answer_length_threshold: @deployment.answer_length_threshold,
          user_stats:              user_stats
        }
      end

      # -----------------------------------------------------------------------
      # Reducer 1 — per-user taggable answer IDs.
      #
      # Streams taggable Answer rows (joined with responses and response_maps,
      # filtered by item type and length threshold). Each row is one (answer, team)
      # pair — answers.id is unique per row so find_each paginates correctly.
      # For each row, adds the answer_id to all users of the team.
      #
      # Output: { user_id => [answer_ids] }
      # -----------------------------------------------------------------------
      class TaggableAnswersReducer < BaseReport
        def initialize(reportable, deployment, item_ids, users_by_team)
          super(reportable)
          @deployment    = deployment
          @item_ids      = item_ids
          @users_by_team = users_by_team
        end

        def source
          return Answer.none if @item_ids.empty?

          Answer
            .taggable_for_assignment(
              @deployment.assignment_id, @item_ids,
              type:      'ReviewResponseMap',
              threshold: @deployment.answer_length_threshold
            )
            .select('answers.id, response_maps.reviewee_id as team_id')
        end

        def state_key_for = ->(answer) { answer.team_id }

        def initial_state
          Hash.new { |state, user_id| state[user_id] = [] }
        end

        def accumulate(state, team_id, answer)
          (@users_by_team[team_id] || []).each do |teams_user|
            state[teams_user.user_id] << answer.id
          end
        end
      end

      # -----------------------------------------------------------------------
      # Reducer 2 — per-user answer tags with answer context.
      #
      # Streams all AnswerTag rows for this deployment (joined with answers).
      # No item or threshold filtering in SQL — the finalize step filters tags
      # by comparing their answer_id against the taggable answer_ids from
      # Reducer 1.
      #
      # Output: { user_id => [{ answer_id:, response_id:, updated_at: }] }
      # -----------------------------------------------------------------------
      class TaggingStatsReducer < BaseReport
        def initialize(reportable, deployment)
          super(reportable)
          @deployment = deployment
        end

        def source
          AnswerTag
            .for_deployment(@deployment.id)
            .joins(:answer)
            .select('answer_tags.id, answer_tags.user_id, answer_tags.answer_id, answer_tags.updated_at, answers.response_id')
        end

        def state_key_for = ->(tag) { tag.user_id }

        def initial_state
          Hash.new { |state, user_id| state[user_id] = [] }
        end

        def accumulate(state, user_id, tag)
          state[user_id] << { answer_id: tag.answer_id, response_id: tag.response_id, updated_at: tag.updated_at }
        end
      end
    end

    # -------------------------------------------------------------------------
    # Reducer 3 — cross-deployment per-user summary.
    # Consumes DeploymentReducer output; no additional DB queries.
    # -------------------------------------------------------------------------
    class UserSummaryReducer
      def initialize(per_deployment_result)
        @per_deployment = per_deployment_result
      end

      def run
        summary = {}
        @per_deployment.each_value do |deployment_data|
          deployment_data[:user_stats].each do |stat|
            key = stat[:user_id]
            if summary.key?(key)
              entry = summary[key]
              entry[:cnt_tagged]     += stat[:cnt_tagged]
              entry[:cnt_not_tagged] += stat[:cnt_not_tagged]
              entry[:cnt_taggable]   += stat[:cnt_taggable]
              entry[:percentage] = entry[:cnt_taggable].zero? ? '-' : format('%.1f', entry[:cnt_tagged].to_f / entry[:cnt_taggable] * 100)
            else
              summary[key] = stat.slice(:user_id, :name, :full_name, :cnt_tagged, :cnt_not_tagged, :cnt_taggable, :percentage)
            end
          end
        end
        summary
      end
    end
  end
end
