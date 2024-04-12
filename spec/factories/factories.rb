FactoryBot.define do

  factory :superadmin, class: User do
    sequence(:name) { |n| "superadmin#{n}" }
    role { Role.where(name: 'Super-Administrator').first || association(:role_of_superadministrator) }
    password { 'password' }
    password_confirmation { 'password' }
    email { 'expertiza@mailinator.com' }
    parent_id { 1 }
    mru_directory_path  { nil }
    email_on_review { true }
    email_on_submission { true }
    email_on_review_of_review { true }
    is_new_user { false }
    master_permission_granted { 0 }
    handle { 'handle' }
    # public_key { nil }
    copy_of_emails { false }
  end

  factory :student, class: User do
    # Zhewei: In order to keep students the same names (2065, 2066, 2064) before each example.
    sequence(:name) { |n| n = n % 3; "student206#{n + 4}" }
    role { Role.where(name: 'Student').first || association(:role_of_student) }
    password { 'password' }
    password_confirmation { 'password' }
    email { 'expertiza@mailinator.com' }
    parent_id { 1 }
    mru_directory_path  { nil }
    email_on_review { true }
    email_on_submission { true }
    email_on_review_of_review { true }
    is_new_user { false }
    master_permission_granted { 0 }
    handle { 'handle' }
    # public_key { nil }
    copy_of_emails { false }
  end

  factory :questionnaire, class: ReviewQuestionnaire do
    name { 'Test questionnaire' }
    # Beware: it is fragile to assume that role_id of instructor is 1 (or any other unchanging value)
    instructor { Instructor.first || association(:instructor) }
    private { 0 }
    min_question_score { 0 }
    max_question_score { 5 }
    # type { 'ReviewQuestionnaire' }
    display_type { 'Review' }
    instruction_loc { nil }
  end

  factory :question, class: Criterion do
    txt { 'Test question:' }
    weight { 1 }
    questionnaire { Questionnaire.first || association(:questionnaire) }
    seq { 1.00 }
    # type { 'Criterion' }
    size { '70,1' }
    alternatives { nil }
    break_before { 1 }
    max_label { nil }
    min_label { nil }
  end

  factory :question_advice, class: QuestionAdvice do
   question { Question.first || association(:question) }
   score { 5 }
   advice { 'LGTM' }
  end

end

