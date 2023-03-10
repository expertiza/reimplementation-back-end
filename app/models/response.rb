# frozen_string_literal: true

class Response < ApplicationRecord

  # return latest versions of the responses
  def self.assessments_for(team)
    responses = []
    if team
      @array_sort = []
      @sort_to = []
      maps = ResponseMap.where(reviewee_id: team.id)
      maps.each do |map|
        next if map.response.empty?

        @all_resp = where(map_id: map.map_id).last
        if map.type.eql?('ReviewResponseMap')
          # If its ReviewResponseMap then only consider those response which are submitted.
          @array_sort << @all_resp if @all_resp.is_submitted
        else
          @array_sort << @all_resp
        end
        # sort all versions in descending order and get the latest one.
        # @sort_to=@array_sort.sort { |m1, m2| (m1.version_num and m2.version_num) ? m2.version_num <=> m1.version_num : (m1.version_num ? -1 : 1) }
        @sort_to = @array_sort.sort # { |m1, m2| (m1.updated_at and m2.updated_at) ? m2.updated_at <=> m1.updated_at : (m1.version_num ? -1 : 1) }
        responses << @sort_to[0] unless @sort_to[0].nil?
        @array_sort.clear
        @sort_to.clear
      end
      responses = responses.sort { |a, b| a.map.reviewer.fullname <=> b.map.reviewer.fullname }
    end
    responses
  end

  # return latest versions of the response given by reviewer
  def self.reviewer_assessments_for(team, reviewer)
    # get_reviewer may return an AssignmentParticipant or an AssignmentTeam
    map = ResponseMap.where(reviewee_id: team.id, reviewer_id: reviewer.id)
    where(map_id: map.first.id).sort.first
  end

end
