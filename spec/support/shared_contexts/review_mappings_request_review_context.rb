# frozen_string_literal: true

RSpec.shared_context 'request review student setup' do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let!(:instructor) do
    User.create!(
      name: 'rrv_instructor', password_digest: 'password',
      role_id: @roles[:instructor].id, full_name: 'RRV Instructor',
      email: 'rrv_instructor@example.com'
    )
  end

  let!(:student) do
    User.create!(
      name: 'rrv_student', password_digest: 'password',
      role_id: @roles[:student].id, full_name: 'RRV Student',
      email: 'rrv_student@example.com'
    )
  end

  let!(:assignment) do
    Assignment.create!(
      name: 'RRV Assignment', instructor: instructor,
      review_assignment_strategy: 'Auto-Selected', review_topic_threshold: 1
    )
  end

  let!(:participant) do
    AssignmentParticipant.create!(
      user_id: student.id, parent_id: assignment.id, handle: student.name
    )
  end

  let(:token)         { JsonWebToken.encode({ id: student.id }) }
  let(:Authorization) { "Bearer #{token}" }
end
