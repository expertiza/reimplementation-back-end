# frozen_string_literal: true

class ProjectTopicSerializer < ActiveModel::Serializer
  attributes :id, :topic_identifier, :topic_name, :assignment_id, :max_choosers,
             :category, :description, :link, :created_at, :updated_at,
             :available_slots, :confirmed_teams, :waitlisted_teams

  def available_slots
    object.available_slots
  end

  def confirmed_teams
    serialize_teams(object.confirmed_teams)
  end

  def waitlisted_teams
    serialize_teams(object.waitlisted_teams)
  end

  private

  def serialize_teams(teams)
    teams.includes(:users).map do |team|
      {
        teamId: team.id.to_s,
        members: team.users.map do |user|
          {
            id: user.id.to_s,
            name: user.full_name.presence || user.name
          }
        end
      }
    end
  end
end
