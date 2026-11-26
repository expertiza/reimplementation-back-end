# frozen_string_literal: true

require 'rails_helper'
require 'json_web_token'

RSpec.describe 'ProjectTopic authorization', type: :request do
  before(:all) { @roles = create_roles_hierarchy }

  def make_user(username, role)
    User.create!(username: username, password_digest: 'password', role_id: @roles[role].id,
                 name: username, email: "#{username}@example.com")
  end

  let(:owner) { make_user('owner', :instructor) }
  let(:stranger) { make_user('stranger', :instructor) }
  let(:student) { make_user('pupil', :student) }
  let!(:assignment) { Assignment.create!(name: 'Owned', instructor_id: owner.id) }
  let!(:foreign) { Assignment.create!(name: 'Foreign', instructor_id: stranger.id) }
  let!(:topic) { assignment.project_topics.create!(topic_name: 'Keep', topic_identifier: 'K1', max_choosers: 1) }
  let!(:foreign_topic) { foreign.project_topics.create!(topic_name: 'Theirs', topic_identifier: 'F1', max_choosers: 1) }

  def headers_for(user)
    { 'Authorization' => "Bearer #{JsonWebToken.encode({ id: user.id })}" }
  end

  def create_topic(user)
    attributes = { assignment_id: assignment.id, topic_name: 'New', max_choosers: 1 }
    post '/project_topics', headers: headers_for(user), as: :json, params: { project_topic: attributes }
  end

  def update_topic(user, attributes)
    patch "/project_topics/#{topic.id}", headers: headers_for(user), as: :json,
                                         params: { project_topic: attributes }
  end

  def delete_topics(user, query)
    delete "/project_topics?#{query}", headers: headers_for(user)
  end

  it 'refuses students and instructors who do not manage the assignment' do
    [student, stranger].each do |user|
      create_topic(user)
      expect(response).to have_http_status(:forbidden)

      update_topic(user, { max_choosers: 9 })
      expect(response).to have_http_status(:forbidden)

      # With and without topic_ids: the latter deletes every topic of the assignment.
      ["assignment_id=#{assignment.id}", "assignment_id=#{assignment.id}&topic_ids[]=K1"].each do |query|
        delete_topics(user, query)
        expect(response).to have_http_status(:forbidden)
      end
    end

    expect(assignment.project_topics.reload).to contain_exactly(topic)
    expect(topic.reload.max_choosers).to eq(1)
  end

  it 'still lets any signed-in user view topics' do
    get "/project_topics?assignment_id=#{assignment.id}", headers: headers_for(student)
    expect(response).to have_http_status(:ok)

    get "/project_topics/#{topic.id}", headers: headers_for(student)
    expect(response).to have_http_status(:ok)
  end

  it 'lets the owning instructor create, update and delete' do
    create_topic(owner)
    expect(response).to have_http_status(:created)

    update_topic(owner, { max_choosers: 4 })
    expect(response).to have_http_status(:ok)

    delete_topics(owner, "assignment_id=#{assignment.id}")
    expect(response).to have_http_status(:no_content)
  end

  it "lets the course's TA change topics" do
    course = Course.create!(name: 'C', instructor_id: owner.id, directory_path: 'c',
                            institution: Institution.create!(name: 'NC State'))
    assignment.update!(course: course)
    ta = make_user('helper', :ta)
    TaMapping.create!(user_id: ta.id, course_id: course.id)

    update_topic(ta, { max_choosers: 2 })
    expect(response).to have_http_status(:ok)
  end

  it 'refuses moving a topic into an assignment the user does not manage' do
    update_topic(owner, { assignment_id: foreign.id })

    expect(response).to have_http_status(:forbidden)
    expect(topic.reload.assignment_id).to eq(assignment.id)
  end

  it "refuses a list of assignment ids that smuggles in someone else's" do
    delete_topics(owner, "assignment_id[]=#{assignment.id}&assignment_id[]=#{foreign.id}")

    expect(response).to have_http_status(:forbidden)
    expect(ProjectTopic.where(id: [topic.id, foreign_topic.id]).count).to eq(2)
  end
end
