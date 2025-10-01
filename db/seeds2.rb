# begin
#     questionnaire_count = 2
#     items_per_questionnaire = 10
#     questionnaire_ids = []
#     questionnaire_count.times do
#         questionnaire_ids << Questionnaire.create!(
#         name: "#{Faker::Lorem.words(number: 5).join(' ').titleize}",
#         instructor_id: rand(1..5), # assuming some instructor IDs exist in range 1–5
#         private: false,
#         min_question_score: 0,
#         max_question_score: 5,
#         questionnaire_type: "ReviewQuestionnaire",
#         display_type: "Review",
#         created_at: Time.now,
#         updated_at: Time.now
#         ).id

#     end
#     puts questionnaire_ids

#     questionnaires = Questionnaire.all

#     questionnaires.each do |questionnaire|
#         items_per_questionnaire.times do |i|
#         Item.create!(
#             txt: Faker::Lorem.sentence(word_count: 8),
#             weight: rand(1..5),
#             seq: i + 1,
#             question_type: ['Criterion', 'Scale', 'TextArea', 'Dropdown'].sample,
#             size: ['50x3', '60x4', '40x2'].sample,
#             alternatives: ['Yes|No', 'Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree'],
#             break_before: true,
#             max_label: Faker::Lorem.word.capitalize,
#             min_label: Faker::Lorem.word.capitalize,
#             questionnaire_id: questionnaire.id,
#             created_at: Time.now,
#             updated_at: Time.now
#         )
#         end
#     end

# end

begin
    count = 4
    count.times do |i|
        AssignmentQuestionnaire.create!(
            assignment_id: i+1,
            questionnaire_id: i+1,
            used_in_round: [1,2].sample
        )
    end
end
