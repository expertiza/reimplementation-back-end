require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  # Create a test controller that inherits from ApplicationController
  # The key fix is to explicitly include before_actions in our anonymous controller
  controller do
    before_action :set_locale
    before_action :authorize
    
    def index
      render plain: 'test controller'
    end
  end

  # Configure routes for testing
  before do
    routes.draw do
      get 'index' => 'anonymous#index'
    end
  end

  describe '#set_locale' do
    before do
      # Store original values to restore after tests
      @original_locales = I18n.available_locales
      @original_default_locale = I18n.default_locale

      # Configure available locales for testing
      I18n.available_locales = [:en, :fr, :es]
      I18n.default_locale = :en
    end

    after do
      # Restore original values
      I18n.available_locales = @original_locales
      I18n.default_locale = @original_default_locale
    end

    it 'ignores invalid locales in params' do
      # Stub authorize just for this test
      allow(controller).to receive(:authorize).and_return(true)
      
      get :index, params: { locale: 'invalid' }
      expect(I18n.locale).to eq(:en) # Should fall back to default
    end

    it 'uses default locale when no valid locale is found' do
      # Stub authorize just for this test
      allow(controller).to receive(:authorize).and_return(true)
      
      request.env['HTTP_ACCEPT_LANGUAGE'] = 'de-DE,de;q=0.9' # Not in available_locales
      get :index
      expect(I18n.locale).to eq(:en) # Default locale
    end
  end

  describe '#extract_locale' do
    before do
      @original_locales = I18n.available_locales
      I18n.available_locales = [:en, :fr, :es]
      
      # Stub authorize for all tests in this context
      allow(controller).to receive(:authorize).and_return(true)
    end

    after do
      I18n.available_locales = @original_locales
    end

    it 'extracts locale from params' do
      get :index, params: { locale: 'fr' }
      expect(controller.send(:extract_locale)).to eq(:fr)
    end

    it 'returns nil for invalid locales in params' do
      get :index, params: { locale: 'invalid' }
      expect(controller.send(:extract_locale)).to be_nil
    end

    it 'extracts first valid locale from Accept-Language header' do
      request.env['HTTP_ACCEPT_LANGUAGE'] = 'fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7'
      get :index
      expect(controller.send(:extract_locale)).to eq(:fr)
    end

    it 'extracts second valid locale from Accept-Language header if first is invalid' do
      request.env['HTTP_ACCEPT_LANGUAGE'] = 'de-DE,de;q=0.9,es-ES;q=0.8,es;q=0.7'
      get :index
      expect(controller.send(:extract_locale)).to eq(:es)
    end

    it 'returns nil when Accept-Language header contains no valid locales' do
      request.env['HTTP_ACCEPT_LANGUAGE'] = 'de-DE,de;q=0.9'
      get :index
      expect(controller.send(:extract_locale)).to be_nil
    end

    it 'handles empty Accept-Language headers gracefully' do
      request.env['HTTP_ACCEPT_LANGUAGE'] = ''
      get :index
      expect(controller.send(:extract_locale)).to be_nil
    end

    it 'handles nil Accept-Language headers gracefully' do
      request.env.delete('HTTP_ACCEPT_LANGUAGE')
      get :index
      expect(controller.send(:extract_locale)).to be_nil
    end
  end

  describe 'language code extraction' do
    before do
      # Stub authorize for all tests in this context
      allow(controller).to receive(:authorize).and_return(true)
    end
    
    it 'correctly extracts country-specific language codes' do
      request.env['HTTP_ACCEPT_LANGUAGE'] = 'en-US,en;q=0.9'
      expect(controller.send(:extract_locale)).to eq(:en)
    end

    it 'correctly handles multi-part language headers' do
      request.env['HTTP_ACCEPT_LANGUAGE'] = 'fr-CA,fr;q=0.9,en-US;q=0.8,en;q=0.7,es;q=0.6'
      expect(controller.send(:extract_locale)).to eq(:fr)
    end

    it 'correctly handles language headers with quality factors' do
      I18n.available_locales = [:en, :fr, :es]
      request.env['HTTP_ACCEPT_LANGUAGE'] = 'de;q=1.0,fr;q=0.9,en;q=0.8'
      expect(controller.send(:extract_locale)).to eq(:fr)
    end
  end
end
