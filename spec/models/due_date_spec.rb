require 'rails_helper'

RSpec.describe DueDate, type: :model do
  let(:due_date1) { DueDate.new(DateTime.new(2024, 12, 25), 'Submission') }
  let(:due_date2) { DueDate.new(DateTime.new(2024, 12, 31), 'Review') }

  describe '#<=>' do
    it 'compares dues dates based on due_at' do
      expect(due_date1 < due_date2).to be true
      expect(due_date1 <=> due_date1).to eq(0)
      expect(due_date2 > due_date1).to be true
    end
  end

  describe '.sort_due_dates' do
    it 'sorts a collection of due dates' do
      due_dates = [due_date2, due_date1]
      expect(DueDate.sort_due_dates(due_dates)).to eq([due_date1, due_date2])
    end
  end

  describe '#due_at_is_valid_datetime' do
    it 'raises an error if due_at is not a DateTime' do
      expect { DueDate.new('invalid date', 'Submission').to raise_error(ArgumentError) }
    end
  end
end