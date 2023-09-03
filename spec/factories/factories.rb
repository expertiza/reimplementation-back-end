FactoryBot.define do
  factory :institution, class: Institution do
    name {'North Carolina State University'}
  end

  factory :role_of_instructor, class: Role do
    name {'Instructor'}
    parent_id {nil}
  end

  factory :instructor, class: Instructor do
    name {'instructor6'}
    role {Role.where(name: 'Instructor').first || association(:role_of_instructor)}
    fullname {'6, instructor'}
    parent_id {1}
    email {'instructor6@gmail.com'}
  end

  factory :course, class: Course do
    sequence(:name) { |n| "CSC517, test#{n}" }
    instructor { Instructor.first || association(:instructor) }
    directory_path {'csc517/test'}
    info {'Object-Oriented Languages and Systems'}
    private {true}
    institution { Institution.first || association(:institution) }
  end


end

