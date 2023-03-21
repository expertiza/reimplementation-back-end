# frozen_string_literal: true

class Response < ApplicationRecord
  include Comparable
  # @return latest versions of responses for a given team
  # @return emtpy collection if a team is not defined
  # @param team is an instance of team or participant
  def self.assessments_for_team(team)
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

  # @return the responses for specified team round
  # @param type is a string that corresponds to Response Map subclasses i.e ReviewResponseMap
  # @param team is an instane of participant or team
  # @param round is integer that corresponds to the response round
  def self.responses_for_team_round(team, round, type)
    responses = []
    if team.id
      maps = ResponseMap.where(reviewee_id: team.id, type: type)
      maps.each do |map|
        if map.response.any? && map.response.reject { |r| (r.round != round || !r.is_submitted) }.any?
          responses << map.response.reject { |r| (r.round != round || !r.is_submitted) }.last
        end
      end
      responses.sort! { |a, b| a.map.reviewer.fullname <=> b.map.reviewer.fullname }
    end
    responses
  end

  # implement rocket so that responses can be compared using response version numbers
  # @param other_response is another instance of response to compare with "this" instance
  def <=>(other_response)
    if version_num && other_response.version_num
      other_response.version_num <=> version_num
    elsif version_num
      -1
    else
      1
    end
  end
end
