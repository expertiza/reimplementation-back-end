# frozen_string_literal: true

require 'rails_helper'
require 'json_web_token'

RSpec.describe 'ProjectTopic CSV import', type: :request do
  before(:all) { @roles = create_roles_hierarchy }

  def make_user(username, role)
    User.create!(username: username, password_digest: 'password', role_id: @roles[role].id,
                 name: username, email: "#{username}@example.com")
  end

  let(:instructor) { make_user('importer', :instructor) }
  let!(:assignment) { Assignment.create!(name: 'Import target', instructor_id: instructor.id) }

  def headers_for(user)
    { 'Authorization' => "Bearer #{JsonWebToken.encode({ id: user.id })}" }
  end

  def upload(content, user: instructor, **extra)
    file = Tempfile.new(['topics', '.csv'])
    file.binmode
    file.write(content)
    file.rewind
    post '/import/ProjectTopic',
         params: { assignment_id: assignment.id, csv_file: Rack::Test::UploadedFile.new(file.path, 'text/csv'), **extra },
         headers: headers_for(user)
  end

  def body
    JSON.parse(response.body)
  end

  it 'describes its fields to the import window' do
    get '/import/ProjectTopic', headers: headers_for(instructor)

    expect(response).to have_http_status(:ok)
    expect(body['mandatory_fields']).to eq(%w[topic_identifier topic_name max_choosers])
    expect(body['available_actions_on_dup']).to eq([])
  end

  it 'matches headers by name in any order, with BOM, quotes and blank lines' do
    upload("﻿Topic Name,TopicIdentifier,max_choosers,Description\n\"Design, build\",T1,2,\"two\nlines\"\n\nPlain,T2,1,\n")

    expect(response).to have_http_status(:created)
    expect(body['message']).to eq('Topics imported: 2 created, 0 updated.')
    expect(assignment.project_topics.find_by(topic_identifier: 'T1'))
      .to have_attributes(topic_name: 'Design, build', max_choosers: 2, description: "two\nlines")
  end

  it 'uses the supplied column order when there is no header row' do
    upload("T1,Alpha,3\n", use_headers: 'false', ordered_fields: %w[topic_identifier topic_name max_choosers].to_json)

    expect(response).to have_http_status(:created)
    expect(assignment.project_topics.first).to have_attributes(topic_name: 'Alpha', max_choosers: 3)
  end

  it 'updates only slots and identifier for an existing topic name' do
    topic = assignment.project_topics.create!(topic_name: 'Alpha', topic_identifier: 'OLD', max_choosers: 1,
                                              category: 'keep')

    upload("topic_identifier,topic_name,max_choosers,category\nNEW,Alpha,5,changed\n")

    expect(body['updated']).to eq(1)
    expect(topic.reload).to have_attributes(topic_identifier: 'NEW', max_choosers: 5, category: 'keep')
  end

  it 'saves nothing and reports every bad row' do
    upload("topic_identifier,topic_name,max_choosers,link\nT1,Good,1,\nWAYTOOLONGID,Long,1,\nT3,,1,\nT4,Slots,abc,\nT1,Dup,1,\nT5,Url,1,#{'x' * 256}\n")

    expect(response).to have_http_status(:unprocessable_entity)
    [3, 4, 5, 6, 7].each { |row| expect(body['error']).to include("Row #{row}:") }
    expect(assignment.project_topics.count).to eq(0)
  end

  it 'rejects unusable files' do
    {
      "topic_name,max_choosers\nA,1\n" => 'Missing required columns: topic_identifier',
      "topic_identifier,topic_name,max_choosers\n" => 'no topic rows',
      "topic_identifier,topic_name,max_choosers\n\"open,A,1\n" => 'Invalid CSV',
      "\xFF\xFE".b => 'UTF-8',
      '' => 'Missing required columns'
    }.each do |content, message|
      upload(content)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(body['error']).to include(message)
    end
  end

  it 'rejects a request with no file or bad ordered_fields' do
    post '/import/ProjectTopic', params: { assignment_id: assignment.id }, headers: headers_for(instructor)
    expect(body['error']).to eq('Choose a CSV file.')

    upload("T1,A,1\n", use_headers: 'false', ordered_fields: 'nope')
    expect(body['error']).to include('ordered_fields')
  end

  it "forbids students and instructors who don't manage the assignment" do
    [make_user('pupil', :student), make_user('stranger', :instructor)].each do |user|
      upload("topic_identifier,topic_name,max_choosers\nT1,A,1\n", user: user)
      expect(response).to have_http_status(:forbidden)
    end
    expect(assignment.project_topics.count).to eq(0)
  end
end
