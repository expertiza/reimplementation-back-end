# frozen_string_literal: true

# Buckets student scores vs instructor "gold" per rubric item for calibration reports.
class CalibrationPerItemSummary
  HEADER_TYPES = %w[SectionHeader TableHeader ColumnHeader section_header table_header column_header].freeze

  def self.skip_item?(item)
    HEADER_TYPES.include?(item.question_type.to_s)
  end

  # instructor_scores_by_item_id: { item_id => Integer or nil }
  # student_rows: [ { answers: [ { item_id:, answer:, comments: } ] } , ... ]
  def self.build(rubric_items, instructor_scores_by_item_id, student_rows)
    scores = (instructor_scores_by_item_id || {}).transform_keys(&:to_i)

    Array(rubric_items).filter_map do |item|
      next if skip_item?(item)

      raw_inst = scores[item.id]
      s = raw_inst.nil? ? nil : raw_inst.to_i

      agree = 0
      near = 0
      disagree = 0
      distribution = Hash.new(0)

      student_rows.each do |row|
        answers = row[:answers] || row['answers'] || []
        ans = answers.find { |a| (a[:item_id] || a['item_id']).to_i == item.id }
        next unless ans

        raw = ans[:answer]
        raw = ans['answer'] if raw.nil?
        next if raw.nil?

        score = raw.to_i
        distribution[score.to_s] += 1

        if s.nil?
          # distribution only
        elsif score == s
          agree += 1
        elsif (score - s).abs == 1
          near += 1
        else
          disagree += 1
        end
      end

      {
        item_id: item.id,
        seq: item.seq.to_i,
        txt: item.txt,
        question_type: item.question_type,
        agree: agree,
        near: near,
        disagree: disagree,
        distribution: distribution.to_h,
        instructor_score: s
      }
    end
  end
end
