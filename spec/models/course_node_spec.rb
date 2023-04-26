require "rails_helper"  

describe CourseNode do
  let(:course) { FactoryBot.build(:course, id: 1) }
  let(:course_node) { FactoryBot.build(:course_node, id: 1) }
  let(:user1) { User.new name: 'abc', fullname: 'abc bbc', email: 'abcbbc@gmail.com', password: '123456789', password_confirmation: '123456789' }
  let(:assignment) { FactoryBot.build(:assignment, id: 1) }

  before(:each) do
    course_node.node_object_id = 1
    allow(course).to receive(:name).and_return("test")
    allow(course).to receive(:private).and_return(true)
    allow(course).to receive(:institutions_id).and_return(1)
    allow(course).to receive(:instructor_id).and_return(1)

    allow(course).to receive(:directory_path).and_return("test")

    allow(course).to receive(:survey_distribution_id).and_return(1)
    allow(Course).to receive(:find_by).with(id: 1).and_return(course)
    allow(User).to receive(:find_by).with(id: 1).and_return(user1)
    allow(User).to receive(:find).with(1).and_return(user1)
    allow(user1).to receive(:id).and_return(1)
  end

  describe '#self.get_privacy_clause(show = nil, user_id = nil)' do
	   it 'The Ruby code  defines a method called `get_privacy_clause` that takes two optional parameters `show` and `user_id`. The method first finds the user whose ID matches `user_id`. Then, it sets `conditions` based on the values of `show` and whether the user is a teaching assistant or not. If `show` is true and the user is not a teaching assistant, `conditions` will be set to `courses.instructor_id = #{user_id}`. If `show` is true and the user is a teaching assistant, `conditions` will be set to `courses.id in (?)`.If `show` is false and the user is not a teaching assistant, `conditions` will be set to `"(courses.private = 0 or courses.instructor_id = #{user_id})"`. If `show` is false and the user is a teaching assistant, `conditions` will be set to `"((courses.private = 0 and courses.instructor_id != #{user_id}) or courses.instructor_id = #{user_id})"`.The method finally returns `conditions`.' do
       allow(user1).to receive(:teaching_assistant?).and_return(false)
       expect(CourseNode.get_privacy_clause(true, 1)).to eq("courses.instructor_id = 1")
     end
  end
  describe '#self.get_privacy_clause(show = nil, user_id = nil) and ta = true' do
    it 'The Ruby code  defines a method called `get_privacy_clause` that takes two optional parameters `show` and `user_id`. The method first finds the user whose ID matches `user_id`. Then, it sets `conditions` based on the values of `show` and whether the user is a teaching assistant or not. If `show` is true and the user is not a teaching assistant, `conditions` will be set to `courses.instructor_id = #{user_id}`. If `show` is true and the user is a teaching assistant, `conditions` will be set to `courses.id in (?)`.If `show` is false and the user is not a teaching assistant, `conditions` will be set to `"(courses.private = 0 or courses.instructor_id = #{user_id})"`. If `show` is false and the user is a teaching assistant, `conditions` will be set to `"((courses.private = 0 and courses.instructor_id != #{user_id}) or courses.instructor_id = #{user_id})"`.The method finally returns `conditions`.' do
      allow(user1).to receive(:teaching_assistant?).and_return(true)
      expect(CourseNode.get_privacy_clause(true, 1)).to eq("courses.id in (?)")
    end
  end

  describe '#self.get_privacy_clause(show = nil, user_id = nil) and ta = false and show = false' do
    it 'The Ruby code  defines a method called `get_privacy_clause` that takes two optional parameters `show` and `user_id`. The method first finds the user whose ID matches `user_id`. Then, it sets `conditions` based on the values of `show` and whether the user is a teaching assistant or not. If `show` is true and the user is not a teaching assistant, `conditions` will be set to `courses.instructor_id = #{user_id}`. If `show` is true and the user is a teaching assistant, `conditions` will be set to `courses.id in (?)`.If `show` is false and the user is not a teaching assistant, `conditions` will be set to `"(courses.private = 0 or courses.instructor_id = #{user_id})"`. If `show` is false and the user is a teaching assistant, `conditions` will be set to `"((courses.private = 0 and courses.instructor_id != #{user_id}) or courses.instructor_id = #{user_id})"`.The method finally returns `conditions`.' do
      allow(user1).to receive(:teaching_assistant?).and_return(false)
      expect(CourseNode.get_privacy_clause(false, 1)).to eq("(courses.private = 0 or courses.instructor_id = 1)")
    end
  end
  describe '#name' do
	   it 'The code defines a method called "get_name". Within the method, it uses the "find_by" method of the "Course" model to search for a record with an ID that matches the value of "node_object_id". If such a record is found, it returns the value of the "name" attribute of that record. If no record is found, it returns nil. The "try" method is used to prevent an error from occurring if the "find_by" method returns nil.' do
       expect(course_node.name).to eq("test")
     end
  end
  describe '#directory_path' do
	   it 'The Ruby code  defines a method `directory_path` which attempts to find a `Course` object by its `id` attribute, using the `find_by` method. If a matching `Course` object is found, the method returns the value of its `directory_path` attribute. If no matching `Course` object is found, the method returns `nil`.' do
       expect(course_node.directory_path).to eq("test")
     end
  end
  describe '#private?' do
	   it 'The Ruby code  defines a method called `private?`. This method attempts to find a `Course` object by its `id` attribute, which is obtained from a variable called `node_object_id`. If a `Course` object is found, the method returns the value of its `private` attribute. If no `Course` object is found, the method returns `nil`.' do
       expect(course_node.private?).to eq(true)

     end
  end
  describe '#instructor_id' do
	   it 'The  Ruby code defines a method called `instructor_id`. This method finds a course with a specific `id` and returns the `instructor_id` associated with that course. If no course is found with the specified `id`, the method returns `nil`. The `try` method is used to avoid a `NoMethodError` if the `find_by` method returns `nil`.' do
       expect(course_node.instructor_id).to eq(1)

     end
  end
  describe '#institution_id' do
	   it 'The ruby code defines a method called "institution_id". This method takes no arguments and attempts to find a Course object in the database with an id equal to the value of "node_object_id". If such a Course object exists, the method returns the value of its "institutions_id" attribute. If no Course object is found or the "institutions_id" attribute is nil, the method returns nil.' do
       expect(course_node.institution_id).to eq(1)

     end
  end

  describe '#survey_distribution_id' do
	   it 'The code defines a method called "get_survey_distribution_id". The method takes no arguments and assumes there is a variable called "node_object_id" which is an ID of a course. The method then attempts to find a course in the database with the given ID using the "find_by" method provided by ActiveRecord. If a course is found, the method returns the value of the "survey_distribution_id" attribute for that course. If no course is found, the method returns nil. Overall, the method is designed to retrieve the survey distribution ID associated with a particular course ID.' do
       expect(course_node.survey_distribution_id).to eq(1)
     end
  end

  describe '#cached_course_lookup' do
    it 'Using course, look up survey distribution id' do
      expect(course_node.cached_course_lookup(:survey_distribution_id)).to eq(1)
    end
  end

end
