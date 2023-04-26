require "rails_helper"

describe AssignmentNode do
  let(:assignment_node) { FactoryBot.build(:assignment_node, id: 1)}
  let(:user1) { User.new name: 'abc', fullname: 'abc bbc', email: 'abcbbc@gmail.com', password: '123456789', password_confirmation: '123456789' }

  before(:each) do
    assignment_node.node_object_id = 1
    allow(User).to receive(:find_by).with(id: 1).and_return(user1)
    allow(User).to receive(:find).with(1).and_return(user1)
    allow(user1).to receive(:id).and_return(1)
  end

  describe '#self.get_privacy_clause when teaching assistant is false' do
  it 'The Ruby code  defines a method called `get_privacy_clause` that takes two optional parameters `show` and `user_id`. The method first finds the user whose ID matches `user_id`. Then, it sets `conditions` based on the values of `show` and whether the user is a teaching assistant or not. If `show` is true and the user is not a teaching assistant, `conditions` will be set to `courses.instructor_id = #{user_id}`. If `show` is true and the user is a teaching assistant, `conditions` will be set to `courses.id in (?)`.If `show` is false and the user is not a teaching assistant, `conditions` will be set to `"(courses.private = 0 or courses.instructor_id = #{user_id})"`. If `show` is false and the user is a teaching assistant, `conditions` will be set to `"((courses.private = 0 and courses.instructor_id != #{user_id}) or courses.instructor_id = #{user_id})"`.The method finally returns `conditions`.' do
    allow(user1).to receive(:teaching_assistant?).and_return(false)
    expect(AssignmentNode.get_privacy_clause(true, 1)).to eq("assignments.instructor_id = 1")
  end
end

describe '#self.get_privacy_clause(show = nil, user_id = nil) and ta = true' do
 it 'The Ruby code  defines a method called `get_privacy_clause` that takes two optional parameters `show` and `user_id`. The method first finds the user whose ID matches `user_id`. Then, it sets `conditions` based on the values of `show` and whether the user is a teaching assistant or not. If `show` is true and the user is not a teaching assistant, `conditions` will be set to `courses.instructor_id = #{user_id}`. If `show` is true and the user is a teaching assistant, `conditions` will be set to `courses.id in (?)`.If `show` is false and the user is not a teaching assistant, `conditions` will be set to `"(courses.private = 0 or courses.instructor_id = #{user_id})"`. If `show` is false and the user is a teaching assistant, `conditions` will be set to `"((courses.private = 0 and courses.instructor_id != #{user_id}) or courses.instructor_id = #{user_id})"`.The method finally returns `conditions`.' do
   allow(user1).to receive(:teaching_assistant?).and_return(true)
   expect(AssignmentNode.get_privacy_clause(true, 1)).to eq("assignments.courses.id in (?)")
 end
end

  describe '#leaf' do
	 it 'The code defines a method named "is_leaf" that always returns a boolean value of true.' do
     expect(AssignmentNode.leaf?).to eq(true)
   end 
  end

end
