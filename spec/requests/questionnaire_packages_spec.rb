# frozen_string_literal: true

require 'rails_helper'
require 'csv'
require 'json'
require 'zip'

RSpec.describe 'QuestionnairePackages API', type: :request do
  before do
    allow_any_instance_of(JwtToken)
      .to receive(:authenticate_request!)
      .and_return(true)

    allow_any_instance_of(Authorization)
      .to receive(:authorize)
      .and_return(true)
  end

  describe 'GET /questionnaire_packages/config' do
    it 'returns questionnaire package configuration' do
      get '/questionnaire_packages/config'

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json['required_files']).to include('manifest.json', 'questionnaires.csv', 'items.csv', 'question_advices.csv')
      expect(json['csv_header_requirements']['questionnaires']).to include('name', 'questionnaire_type', 'instructor_name')
      expect(json['csv_header_requirements']['items']).to include('questionnaire_name', 'seq', 'txt')
      expect(json['csv_header_requirements']['question_advices']).to include('questionnaire_name', 'item_seq', 'advice')
      expect(json['available_templates']).to include('questionnaires', 'items', 'question_advices', 'package')
      expect(json['package_type']).to eq('questionnaire_template_export')
      expect(json['version']).to eq(1)
      expect(json['available_actions_on_dup']).to include('SkipRecordAction', 'UpdateExistingRecordAction', 'ChangeOffendingFieldAction')
    end
  end

  describe 'GET /questionnaire_packages/templates/:template_name' do
    it 'downloads a CSV template with a sample row' do
      get '/questionnaire_packages/templates/items'

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json['filename']).to eq('items_import_sample.csv')
      expect(json['content_type']).to eq('text/csv')

      csv = CSV.parse(Base64.decode64(json['data']), headers: true)
      expect(csv.headers).to include('questionnaire_name', 'seq', 'txt', 'question_type')
      expect(csv.count).to eq(1)
      expect(csv.first['questionnaire_name']).to eq('Sample Review Questionnaire')
      expect(csv.first['txt']).to eq('How clear is the submitted work?')
    end

    it 'downloads a package template zip with sample rows' do
      get '/questionnaire_packages/templates/package'

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json['filename']).to eq('questionnaire_package_import_sample.zip')
      expect(json['content_type']).to eq('application/zip')

      contents = read_zip_entries(json['data'])
      expect(contents.keys).to contain_exactly('manifest.json', 'questionnaires.csv', 'items.csv', 'question_advices.csv')
      expect(JSON.parse(contents['manifest.json'])).to include(
        'package_type' => 'questionnaire_template_export',
        'version' => 1
      )
      expect(CSV.parse(contents['questionnaires.csv'], headers: true).headers).to include('name', 'questionnaire_type', 'instructor_name')
      expect(CSV.parse(contents['items.csv'], headers: true).headers).to include('questionnaire_name', 'seq', 'txt')
      expect(CSV.parse(contents['question_advices.csv'], headers: true).headers).to include('questionnaire_name', 'item_seq', 'advice')
      expect(CSV.parse(contents['questionnaires.csv'], headers: true).first['name']).to eq('Sample Review Questionnaire')
      expect(CSV.parse(contents['items.csv'], headers: true).first['txt']).to eq('How clear is the submitted work?')
      expect(CSV.parse(contents['question_advices.csv'], headers: true).first['advice']).to eq('Mention the strongest evidence and reasoning.')
    end

    it 'rejects unknown template names' do
      get '/questionnaire_packages/templates/unknown'

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to include('Unsupported questionnaire package template')
    end
  end

  describe 'POST /questionnaire_packages/export' do
    it 'exports a questionnaire template package without answers, responses, or quiz data' do
      role = create(:role, :instructor)
      institution = create(:institution)
      instructor = Instructor.create!(
        name: 'packageexporter',
        email: 'packageexporter@example.com',
        full_name: 'Package Exporter',
        password: 'password',
        role: role,
        institution: institution
      )

      questionnaire = Questionnaire.create!(
        name: 'Package Questionnaire',
        instructor: instructor,
        private: false,
        min_question_score: 0,
        max_question_score: 10,
        questionnaire_type: 'ReviewQuestionnaire',
        display_type: 'Likert',
        instruction_loc: 'instructions'
      )

      item = Item.create!(
        questionnaire: questionnaire,
        txt: 'How clear was the feedback?',
        weight: 2,
        seq: 1,
        question_type: 'Scale',
        break_before: true
      )

      QuestionAdvice.create!(item: item, score: 4, advice: 'Be more specific.')

      assignment = create(:assignment, instructor: instructor)
      reviewer = create(:assignment_participant, assignment: assignment)
      reviewee = create(:assignment_participant, assignment: assignment)
      response_map = ResponseMap.create!(
        reviewer_id: reviewer.id,
        reviewee_id: reviewee.id,
        reviewed_object_id: assignment.id
      )
      review_response = Response.create!(
        map_id: response_map.id,
        additional_comment: 'Do not export this response'
      )
      Answer.create!(
        item: item,
        response: review_response,
        answer: 3,
        comments: 'Do not export this answer'
      )

      quiz_questionnaire = Questionnaire.create!(
        name: 'Quiz Questionnaire',
        instructor: instructor,
        private: false,
        min_question_score: 0,
        max_question_score: 10,
        questionnaire_type: 'QuizQuestionnaire',
        display_type: 'Quiz',
        instruction_loc: 'quiz instructions'
      )

      Item.create!(
        questionnaire: quiz_questionnaire,
        txt: 'Quiz question',
        weight: 1,
        seq: 1,
        question_type: 'multiple_choice',
        break_before: true
      )

      post '/questionnaire_packages/export', params: { export_all: true }

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json['filename']).to end_with('.zip')
      expect(json['counts']['questionnaires']).to eq(1)

      contents = read_zip_entries(json['data'])
      expect(contents.keys).to contain_exactly('manifest.json', 'questionnaires.csv', 'items.csv', 'question_advices.csv')
      manifest = JSON.parse(contents['manifest.json'])
      expect(manifest).to include(
        'package_type' => 'questionnaire_template_export',
        'version' => 1,
        'includes' => %w[questionnaires items question_advices],
        'excludes' => %w[answers responses quiz_questionnaires quiz_items quiz_question_choices]
      )

      questionnaire_rows = CSV.parse(contents['questionnaires.csv'], headers: true)
      item_rows = CSV.parse(contents['items.csv'], headers: true)
      advice_rows = CSV.parse(contents['question_advices.csv'], headers: true)

      expect(questionnaire_rows.map { |row| row['name'] }).to contain_exactly('Package Questionnaire')
      expect(item_rows.map { |row| row['txt'] }).to contain_exactly('How clear was the feedback?')
      expect(advice_rows.map { |row| row['advice'] }).to contain_exactly('Be more specific.')
      expect(json['counts']).to include(
        'questionnaires' => 1,
        'items' => 1,
        'question_advices' => 1
      )

      package_text = contents.values.join("\n")
      expect(package_text).not_to include('answers.csv')
      expect(package_text).not_to include('responses.csv')
      expect(package_text).not_to include('quiz_question_choices.csv')
      expect(package_text).not_to include('Do not export this response')
      expect(package_text).not_to include('Do not export this answer')
      expect(package_text).not_to include('Quiz Questionnaire')
      expect(package_text).not_to include('Quiz question')
    end
  end

  describe 'POST /questionnaire_packages/import' do
    it 'previews separate CSV uploads without importing records' do
      role = create(:role, :instructor)
      institution = create(:institution)
      Instructor.create!(
        name: 'previewimporter',
        email: 'previewimporter@example.com',
        full_name: 'Preview Importer',
        password: 'password',
        role: role,
        institution: institution
      )

      questionnaire_file = build_csv_upload(
        filename: 'preview questionnaires.csv',
        contents: <<~CSV
          name,questionnaire_type,display_type,private,min_question_score,max_question_score,instruction_loc,instructor_name
          Preview Questionnaire,ReviewQuestionnaire,Likert,false,0,5,instructions,previewimporter
        CSV
      )
      items_file = build_csv_upload(
        filename: 'preview items.csv',
        contents: <<~CSV
          questionnaire_name,questionnaire_instructor_name,seq,txt,question_type,weight,break_before,min_label,max_label,alternatives,size
          Preview Questionnaire,previewimporter,1,Preview item,Scale,2,true,poor,excellent,,
        CSV
      )
      question_advices_file = build_csv_upload(
        filename: 'preview advices.csv',
        contents: <<~CSV
          questionnaire_name,questionnaire_instructor_name,item_seq,item_txt,score,advice
          Preview Questionnaire,previewimporter,1,Preview item,5,Preview advice
        CSV
      )

      post '/questionnaire_packages/preview', params: {
        questionnaire_file: questionnaire_file,
        items_file: items_file,
        question_advices_file: question_advices_file
      }

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json['summary']).to include(
        'questionnaires' => 1,
        'items' => 1,
        'question_advices' => 1,
        'creates' => 3,
        'errors' => 0
      )
      expect(json['questionnaires'].first).to include(
        'name' => 'Preview Questionnaire',
        'action' => 'create'
      )
      expect(json['items'].first).to include('txt' => 'Preview item', 'action' => 'create')
      expect(json['question_advices'].first).to include('advice' => 'Preview advice', 'action' => 'create')
      expect(Questionnaire.find_by(name: 'Preview Questionnaire')).to be_nil
    end

    it 'previews duplicate and unresolved rows' do
      role = create(:role, :instructor)
      institution = create(:institution)
      instructor = Instructor.create!(
        name: 'previewduplicate',
        email: 'previewduplicate@example.com',
        full_name: 'Preview Duplicate',
        password: 'password',
        role: role,
        institution: institution
      )
      Questionnaire.create!(
        name: 'Preview Duplicate Questionnaire',
        instructor: instructor,
        private: false,
        min_question_score: 0,
        max_question_score: 5,
        questionnaire_type: 'ReviewQuestionnaire',
        display_type: 'Likert',
        instruction_loc: 'old instructions'
      )

      questionnaire_file = build_csv_upload(
        filename: 'preview duplicate questionnaires.csv',
        contents: <<~CSV
          name,questionnaire_type,display_type,private,min_question_score,max_question_score,instruction_loc,instructor_name
          Preview Duplicate Questionnaire,ReviewQuestionnaire,Likert,false,0,5,instructions,previewduplicate
          Missing Instructor Questionnaire,ReviewQuestionnaire,Likert,false,0,5,instructions,missingpreviewinstructor
        CSV
      )
      items_file = build_csv_upload(
        filename: 'preview duplicate items.csv',
        contents: <<~CSV
          questionnaire_name,questionnaire_instructor_name,seq,txt,question_type,weight,break_before,min_label,max_label,alternatives,size
          Preview Duplicate Questionnaire,previewduplicate,1,Duplicate preview item,Scale,2,true,,,
          Missing Instructor Questionnaire,missingpreviewinstructor,1,Missing instructor item,Scale,2,true,,,
        CSV
      )

      post '/questionnaire_packages/preview', params: {
        questionnaire_file: questionnaire_file,
        items_file: items_file,
        dup_action: 'UpdateExistingRecordAction'
      }

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json['summary']).to include(
        'questionnaires' => 2,
        'items' => 2,
        'duplicates' => 1,
        'updates' => 1,
        'errors' => 2
      )
      expect(json['questionnaires'].first).to include('action' => 'update', 'duplicate' => true)
      expect(json['errors'].map { |error| error['file'] }).to include('questionnaires', 'items')
    end

    it 'imports questionnaire packages from a zip file' do
      role = create(:role, :instructor)
      institution = create(:institution)
      Instructor.create!(
        name: 'packageimporter',
        email: 'packageimporter@example.com',
        full_name: 'Package Importer',
        password: 'password',
        role: role,
        institution: institution
      )

      uploaded_file = build_package_upload(
        manifest: {
          package_type: 'questionnaire_template_export',
          version: 1,
          files: %w[questionnaires.csv items.csv question_advices.csv]
        },
        questionnaires_csv: <<~CSV,
          name,questionnaire_type,display_type,private,min_question_score,max_question_score,instruction_loc,instructor_name
          Imported Questionnaire,ReviewQuestionnaire,Likert,false,0,5,instructions,packageimporter
        CSV
        items_csv: <<~CSV,
          questionnaire_name,questionnaire_instructor_name,seq,txt,question_type,weight,break_before,min_label,max_label,alternatives,size
          Imported Questionnaire,packageimporter,1,Imported item,Scale,2,true,poor,excellent,,
        CSV
        question_advices_csv: <<~CSV
          questionnaire_name,questionnaire_instructor_name,item_seq,item_txt,score,advice
          Imported Questionnaire,packageimporter,1,Imported item,5,Great work
        CSV
      )

      post '/questionnaire_packages/import', params: {
        package_file: uploaded_file,
        dup_action: 'ChangeOffendingFieldAction'
      }

      expect(response).to have_http_status(:created)

      imported_questionnaire = Questionnaire.find_by(name: 'Imported Questionnaire')
      expect(imported_questionnaire).to be_present
      expect(imported_questionnaire.items.find_by(txt: 'Imported item')).to be_present
      expect(QuestionAdvice.joins(:item).find_by(items: { txt: 'Imported item' }, advice: 'Great work')).to be_present

      json = JSON.parse(response.body)
      expect(json['imported']).to include(
        'questionnaires' => 1,
        'items' => 1,
        'question_advices' => 1
      )
    end

    it 'rejects unsupported package manifests' do
      uploaded_file = build_package_upload(
        manifest: {
          package_type: 'questionnaire_export',
          version: 1,
          files: %w[questionnaires.csv items.csv question_advices.csv]
        },
        questionnaires_csv: "name,questionnaire_type,display_type,private,min_question_score,max_question_score,instruction_loc,instructor_name\n",
        items_csv: "questionnaire_name,questionnaire_instructor_name,seq,txt,question_type,weight,break_before,min_label,max_label,alternatives,size\n",
        question_advices_csv: "questionnaire_name,questionnaire_instructor_name,item_seq,item_txt,score,advice\n"
      )

      post '/questionnaire_packages/import', params: {
        package_file: uploaded_file
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to include('Unsupported questionnaire package type')
    end

    it 'imports questionnaire CSVs from role-specific fields without requiring specific filenames' do
      role = create(:role, :instructor)
      institution = create(:institution)
      Instructor.create!(
        name: 'csvroleimporter',
        email: 'csvroleimporter@example.com',
        full_name: 'CSV Role Importer',
        password: 'password',
        role: role,
        institution: institution
      )

      questionnaire_file = build_csv_upload(
        filename: 'my rubric list.csv',
        contents: <<~CSV
          name,questionnaire_type,display_type,private,min_question_score,max_question_score,instruction_loc,instructor_name
          Role Field Questionnaire,ReviewQuestionnaire,Likert,false,0,5,instructions,csvroleimporter
        CSV
      )
      items_file = build_csv_upload(
        filename: 'these are the questions.csv',
        contents: <<~CSV
          questionnaire_name,questionnaire_instructor_name,seq,txt,question_type,weight,break_before,min_label,max_label,alternatives,size
          Role Field Questionnaire,csvroleimporter,1,Role field item,Scale,2,true,poor,excellent,,
        CSV
      )
      question_advices_file = build_csv_upload(
        filename: 'helpful scoring notes.csv',
        contents: <<~CSV
          questionnaire_name,questionnaire_instructor_name,item_seq,item_txt,score,advice
          Role Field Questionnaire,csvroleimporter,1,Role field item,5,Well done
        CSV
      )

      post '/questionnaire_packages/import', params: {
        questionnaire_file: questionnaire_file,
        items_file: items_file,
        question_advices_file: question_advices_file,
        dup_action: 'ChangeOffendingFieldAction'
      }

      expect(response).to have_http_status(:created)

      imported_questionnaire = Questionnaire.find_by(name: 'Role Field Questionnaire')
      expect(imported_questionnaire).to be_present
      expect(imported_questionnaire.items.find_by(txt: 'Role field item')).to be_present
      expect(QuestionAdvice.joins(:item).find_by(items: { txt: 'Role field item' }, advice: 'Well done')).to be_present
    end

    it 'validates separate CSV uploads by required headers' do
      questionnaire_file = build_csv_upload(
        filename: 'bad questionnaire upload.csv',
        contents: <<~CSV
          name,questionnaire_type
          Missing Headers,ReviewQuestionnaire
        CSV
      )

      post '/questionnaire_packages/import', params: {
        questionnaire_file: questionnaire_file
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to include('Questionnaires CSV is missing required headers')
    end

    it 'renames duplicate questionnaires when using the default duplicate action' do
      role = create(:role, :instructor)
      institution = create(:institution)
      instructor = Instructor.create!(
        name: 'duplicatedpackageimporter',
        email: 'duplicatedpackageimporter@example.com',
        full_name: 'Duplicated Package Importer',
        password: 'password',
        role: role,
        institution: institution
      )
      Questionnaire.create!(
        name: 'Duplicate Questionnaire',
        instructor: instructor,
        private: false,
        min_question_score: 0,
        max_question_score: 5,
        questionnaire_type: 'ReviewQuestionnaire',
        display_type: 'Likert',
        instruction_loc: 'old instructions'
      )

      uploaded_file = build_package_upload(
        manifest: {
          package_type: 'questionnaire_template_export',
          version: 1,
          files: %w[questionnaires.csv items.csv question_advices.csv]
        },
        questionnaires_csv: <<~CSV,
          name,questionnaire_type,display_type,private,min_question_score,max_question_score,instruction_loc,instructor_name
          Duplicate Questionnaire,ReviewQuestionnaire,Likert,false,0,5,new instructions,duplicatedpackageimporter
        CSV
        items_csv: <<~CSV,
          questionnaire_name,questionnaire_instructor_name,seq,txt,question_type,weight,break_before,min_label,max_label,alternatives,size
          Duplicate Questionnaire,duplicatedpackageimporter,1,Duplicated item,Scale,1,true,,,
        CSV
        question_advices_csv: "questionnaire_name,questionnaire_instructor_name,item_seq,item_txt,score,advice\n"
      )

      post '/questionnaire_packages/import', params: {
        package_file: uploaded_file
      }

      expect(response).to have_http_status(:created)
      copied_questionnaire = Questionnaire.find_by(name: 'Duplicate Questionnaire_copy')
      expect(copied_questionnaire).to be_present
      expect(copied_questionnaire.items.find_by(txt: 'Duplicated item')).to be_present
      expect(JSON.parse(response.body)['duplicates']).to include('questionnaires' => 1)
    end
  end

  def read_zip_entries(encoded_data)
    buffer = StringIO.new(Base64.decode64(encoded_data))
    contents = {}

    Zip::File.open_buffer(buffer) do |zip_file|
      zip_file.each do |entry|
        contents[entry.name] = entry.get_input_stream.read
      end
    end

    contents
  end

  def build_package_upload(manifest:, questionnaires_csv:, items_csv:, question_advices_csv:)
    file = Tempfile.new(['questionnaire_package', '.zip'])

    Zip::OutputStream.open(file.path) do |zip|
      zip.put_next_entry('manifest.json')
      zip.write(JSON.generate(manifest))

      zip.put_next_entry('questionnaires.csv')
      zip.write(questionnaires_csv)

      zip.put_next_entry('items.csv')
      zip.write(items_csv)

      zip.put_next_entry('question_advices.csv')
      zip.write(question_advices_csv)
    end

    Rack::Test::UploadedFile.new(file.path, 'application/zip')
  end

  def build_csv_upload(filename:, contents:)
    file = Tempfile.new([File.basename(filename, '.csv'), '.csv'])
    file.write(contents)
    file.rewind

    Rack::Test::UploadedFile.new(file.path, 'text/csv', original_filename: filename)
  end
end
