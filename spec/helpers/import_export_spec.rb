# frozen_string_literal: true

require 'rails_helper'
require 'csv'

RSpec.describe ImportableExportableHelper, type: :helper do
  include RolesHelper
  

  before(:all) do
    @roles = create_roles_hierarchy

    @institution = Institution.create!(name: 'NC State')


    @instructor = Instructor.create!(
      name: 'instructor',
      full_name: 'Instructor User',
      email: 'instructor@example.com',
      password_digest: 'password',
      role: @roles[:instructor],
      institution: @institution
    )

    @questionnaire = Questionnaire.create!(
      name: 'Test Questionnaire',
      questionnaire_type: '',
      private: true,
      min_question_score: 1,
      max_question_score: 10,
      instructor: @instructor
    )
  end


  describe 'Create tests for each of the different importable classes' do
    it 'Import a class with no headers' do
      expect(User.count).to eq(1)

      csv_file = file_fixture('single_user_no_headers.csv')
      headers = ['Name', 'Email', 'Password', 'Full Name', 'Role Name']

      User.try_import_records(csv_file, headers, use_header: false)

      expect(User.count).to eq(2)
      expect(User.find_by(email: 'jdoe@email.com')).to be_present
    end

    it 'Import a class with headers' do
      expect(User.count).to eq(1)

      csv_file = file_fixture('single_user_with_headers.csv')

      User.try_import_records(csv_file, nil, use_header: true)

      expect(User.count).to eq(2)
      expect(User.find_by(email: 'jdoe@email.com')).to be_present
    end

    it 'Import a file with multiple records' do
      expect(User.count).to eq(1)

      csv_file = file_fixture('multiple_users_with_headers.csv')

      User.try_import_records(csv_file, nil, use_header: true)

      expect(User.count).to eq(3)
      expect(User.find_by(email: 'jdoe@email.com')).to be_present
      expect(User.find_by(email: 'jndoe@email.com')).to be_present
    end

    it 'Import a class with external lookup and create classes, and can take duplicate headers' do
      expect(Questionnaire.count).to eq(1)
      expect(Questionnaire.find_by(name: 'Test Questionnaire')).to be_present
      expect(QuizItem.count).to eq(0)
      expect(QuestionAdvice.count).to eq(0)

      csv_file = file_fixture('questionnaire_item_with_headers.csv')
      QuizItem.try_import_records(csv_file, nil, use_header: true)

      expect(QuizItem.count).to eq(1)
      expect(QuizItem.find_by(txt: 'test')).to be_present

      expect(QuestionAdvice.count).to eq(2)

      advice_one = QuestionAdvice.find_by(advice: 'okay')
      expect(advice_one).to be_present
      expect(advice_one.score).to eq(1)
      expect(advice_one.item.txt).to eq('test')

      advice_two = QuestionAdvice.find_by(advice: 'good')
      expect(advice_two).to be_present
      expect(advice_two.score).to eq(2)
      expect(advice_two.item.txt).to eq('test')
    end
  end


  # * Create a test with external lookup class that doesn't exist
  # * Create a test with an empty CSV (With Headers)
  # * Create a test with an empty CSV (Without Headers)
  describe 'Create Tests to test Errors/Edge Cases' do
    it 'Import a class with an invalid field (User with invalid email)' do
      csv_file = file_fixture('single_user_email_invalid.csv')

      expect {User.try_import_records(csv_file, nil, use_header: true)}.to raise_error
    end

    it 'Import a class with external lookup class that does not exist' do
      expect(User.count).to eq(1)

      csv_file = file_fixture('single_user_role_doe_not_exist.csv')

      expect { User.try_import_records(csv_file, nil, use_header: true) }.to raise_error

      expect(User.count).to eq(1)
      expect(User.find_by(email: 'jdoe@email.com')).not_to be_present
    end

    it 'Import an empty CSV (With Headers)' do
      csv_file = file_fixture('empty_with_headers.csv')

      expect{User.try_import_records(csv_file, nil, use_header: true)}.not_to change(User, :count)
    end

    it 'Import an empty CSV (Without Headers)' do
      csv_file = file_fixture('empty.csv')

      expect{User.try_import_records(csv_file, [], use_header: false)}.not_to change(User, :count)
    end


  end

end
