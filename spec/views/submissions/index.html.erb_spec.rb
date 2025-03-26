require 'rails_helper'

RSpec.describe "submissions/index.html.erb", type: :view do
  before do
    # Create mock data for the tests
    @user = create(:user, name: "Test User") # Replace with your actual User model factory
  end

  context "when there are submission records" do
    before do
      # Creating some submission records
      @submission_records = create_list(:submission, 3, user: @user)
      assign(:submission_records, @submission_records)

      render # Renders the view
    end

    it "displays the submission history table" do
      expect(rendered).to have_selector('table.table-striped') # Check for the table
    end

    it "displays the submission details correctly" do
      @submission_records.each do |record|
        expect(rendered).to include(record.id.to_s)
        expect(rendered).to include(record.user.name)
        expect(rendered).to include(record.created_at.strftime("%Y-%m-%d %H:%M:%S"))
        expect(rendered).to include(truncate(record.content, length: 50))
      end
    end
  end

  context "when there are no submission records" do
    before do
      # No submission records
      @submission_records = []
      assign(:submission_records, @submission_records)

      render
    end

    it "displays a message saying no records found" do
      expect(rendered).to include("No submission records found for this team.")
    end
  end
end
