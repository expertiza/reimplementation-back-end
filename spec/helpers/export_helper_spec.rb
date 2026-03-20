# frozen_string_literal: true

require 'rails_helper'
require 'csv'
require 'json'

RSpec.describe ExportHelper, type: :helper do
  describe '.build_has_many_graph' do
    it 'captures ExternalClass relation and infers question_advices from belongs_to :item' do
      graph = described_class.build_has_many_graph(Questionnaire)

      puts "\nExport Graph:"
      puts JSON.pretty_generate(graph)

      expect(graph[:class_name]).to eq('Questionnaire')

      items_node = graph[:has_many].find { |node| node[:association] == 'items' }
      expect(items_node).to be_present
      expect(items_node[:association_type]).to eq('has_many')

      item_graph = items_node[:graph]
      relation = item_graph[:parent_external_relation]

      expect(item_graph[:class_name]).to eq('Item')
      expect(relation).to be_present
      expect(relation[:ref_class]).to eq('Questionnaire')
      expect(relation[:fields]).to include('questionnaire_name')

      question_advices_node = item_graph[:has_many].find { |node| node[:association] == 'question_advices' }
      expect(question_advices_node).to be_present
      expect(question_advices_node[:association_type]).to eq('inferred_has_many_from_belongs_to')
      expect(question_advices_node[:inferred_from]).to eq('item')
      expect(question_advices_node[:graph][:class_name]).to eq('QuestionAdvice')
    end
  end

  describe '.export_has_many_graph' do
    it 'uses mandatory fields and includes inferred QuestionAdvice export' do
      calls = {}

      allow(Export).to receive(:perform) do |klass, headers|
        calls[klass.name] = headers
        CSV.generate do |csv|
          csv << headers
          csv << headers.map { |header| "#{klass.name.downcase}_#{header}" }
        end
      end

      result = described_class.export_has_many_graph(Questionnaire)

      puts "\nExport Graph (from export_has_many_graph):"
      puts JSON.pretty_generate(result[:graph])

      puts "\nCSV Exports:"
      result[:exports].each do |klass_name, csv_text|
        puts "--- #{klass_name} ---"
        puts csv_text
      end

      expect(result).to have_key(:graph)
      expect(result).to have_key(:exports)
      expect(result[:exports]).to include('Questionnaire')
      expect(result[:exports]).to include('Item')
      expect(result[:exports]).to include('QuestionAdvice')

      expect(Questionnaire.mandatory_fields - calls['Questionnaire']).to be_empty
      expect(calls['Questionnaire']).not_to include('id')

      expect(Item.mandatory_fields - calls['Item']).to be_empty
      expect(calls['Item']).to include('questionnaire_name')
      expect(calls['Item']).not_to include('id')

      expect(QuestionAdvice.mandatory_fields - calls['QuestionAdvice']).to be_empty
      expect(calls['QuestionAdvice']).not_to include('id')
    end
  end
end
