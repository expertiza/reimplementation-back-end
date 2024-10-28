class TopicDueDate < DueDate
  def self.next_due_date(assignment_id, topic_id)
    next_due_date = where('parent_id = ? and due_at >= ?', topic_id, Time.zone.now)
    puts 'hi', next_due_date

    if next_due_date.nil?
      topic_due_date_size = where(parent_id: topic_id).size
      following_assignment_due_dates = AssignmentDueDate.where(parent_id: assignment_id)[topic_due_date_size..-1]
      puts 'hi2', following_assignment_due_dates

      unless following_assignment_due_dates.nil?
        next_due_date = following_assignment_due_dates.find do |assignment_due_date|
          assignment_due_date.due_at >= Time.zone.now
        end
      end
    end

    next_due_date
  end
end