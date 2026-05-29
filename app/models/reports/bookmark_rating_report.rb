# frozen_string_literal: true

module Reports
  # Bookmark-rating report: which bookmarks were rated under this assignment
  # and the associated project topics.
  #
  # Accumulator: groups BookmarkRatingResponseMap rows by reviewee_id (the
  # bookmark being rated) and collects distinct bookmark IDs in one pass.
  # Project topics are fetched separately (one query) since they are not
  # streamed per row.
  class BookmarkRatingReport < BaseReport
    def source
      BookmarkRatingResponseMap.where(reviewed_object_id: @reportable.id)
    end

    def state_key_for       = ->(map) { map.reviewee_id }
    def initial_state = Set.new

    def accumulate(state, bookmark_id, _map)
      state.add(bookmark_id)
    end

    def finalize(bookmark_ids)
      topics = @reportable.project_topics.map { |t| { id: t.id, topic_name: t.topic_name } }
      { bookmark_ids: bookmark_ids.to_a, topics: topics }
    end
  end
end
