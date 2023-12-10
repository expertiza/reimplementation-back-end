# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Seed teams_users
TeamsUser.create(
  team_id: 1,
  user_id: 1,
  duty_id: 1,
  pair_programming_status: 'Accepted', # Assuming 'A' represents some status
  participant_id: 3
)

TeamsUser.create(
  team_id: 2,
  user_id: 2,
  duty_id: 2,
  pair_programming_status: 'Invited', # Assuming 'B' represents some other status
  participant_id: 5
)
