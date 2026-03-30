# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CalibrationPerItemSummary do
  let(:q) { Questionnaire.create!(name: 'R', min_question_score: 1, max_question_score: 5) }
  let(:item1) do
    Item.create!(questionnaire: q, txt: 'Q1', weight: 1, seq: 1, question_type: 'scale', break_before: true)
  end
  let(:item2) do
    Item.create!(questionnaire: q, txt: 'Header', weight: 0, seq: 2, question_type: 'SectionHeader', break_before: true)
  end

  it 'buckets agree / near / disagree vs instructor scores' do
    instructor = { item1.id => 3 }
    students = [
      { answers: [{ item_id: item1.id, answer: 3, comments: '' }] },
      { answers: [{ item_id: item1.id, answer: 4, comments: '' }] },
      { answers: [{ item_id: item1.id, answer: 1, comments: '' }] }
    ]
    rows = described_class.build([item1, item2], instructor, students)
    r1 = rows.find { |h| h[:item_id] == item1.id }
    expect(r1[:agree]).to eq(1)
    expect(r1[:near]).to eq(1)
    expect(r1[:disagree]).to eq(1)
    expect(r1[:distribution]['3']).to eq(1)
    expect(r1[:distribution]['4']).to eq(1)
    expect(r1[:distribution]['1']).to eq(1)
  end

  it 'skips section headers' do
    instructor = { item1.id => 2 }
    students = [{ answers: [{ item_id: item1.id, answer: 2, comments: '' }] }]
    rows = described_class.build([item1, item2], instructor, students)
    expect(rows.map { |h| h[:item_id] }).to contain_exactly(item1.id)
  end
end
