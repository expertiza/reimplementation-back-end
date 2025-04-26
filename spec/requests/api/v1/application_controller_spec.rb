require 'rails_helper'

# This spec tests the core functionality of the ApplicationController
# which handles internationalization (i18n), authentication, and
# other cross-cutting concerns for the entire application
RSpec.describe ApplicationController, type: :controller do
  # Creates an anonymous controller for testing ApplicationController functionality
  # This technique allows testing of methods that would normally be protected or private
  # in a real controller instance without having to expose them unnecessarily
  controller do
    before_action :set_locale
    before_action :authorize
    
    def index
      render plain: 'test controller'
    end
  end

  # Sets up temporary routes for our anonymous controller
  # This allows us to make requests to the controller during tests
  before do
    routes.draw do
      get 'index' => 'anonymous#index'
    end
  end

  # Tests for the set_locale method which handles internationalization
  # This method determines which language/locale to use based on user preferences,
  # URL parameters, browser settings, and system defaults
  describe '#set_locale' do
    before do
      # Store original values to restore after tests
      # This prevents our tests from affecting other tests that rely on these settings
      @original_locales = I18n.available_locales
      @original_default_locale = I18n.default_locale

      # Configure available locales for testing
      # We use a limited set of locales to make testing more predictable
      I18n.available_locales = [:en, :fr, :es]
      I18n.default_locale = :en
    end

    after do
      # Restore original values to prevent test pollution
      # This ensures our locale changes don't affect other tests
      I18n.available_locales = @original_locales
      I18n.default_locale = @original_default_locale
    end

    # Verifies that invalid locales are ignored and the default is used instead
    # This prevents errors when users manually enter invalid locale parameters
    it 'ignores invalid locales in params' do
      # Stub authorize just for this test to focus on locale handling
      allow(controller).to receive(:authorize).and_return(true)
      
      get :index, params: { locale: 'invalid' }
      expect(I18n.locale).to eq(:en) # Should fall back to default
    end

    # Tests the fallback behavior when no valid locale is found in any source
    # This ensures users always get a working interface even with unusual browser settings
    it 'uses default locale when no valid locale is found' do
      # Stub authorize just for this test
      allow(controller).to receive(:authorize).and_return(true)
      
      request.env['HTTP_ACCEPT_LANGUAGE'] = 'de-DE,de;q=0.9' # Not in available_locales
      get :index
      expect(I18n.locale).to eq(:en) # Default locale
    end
  end

  # Tests the extract_locale method which determines which locale to use
  # from various sources including URL parameters and HTTP headers
  describe '#extract_locale' do
    before do
      @original_locales = I18n.available_locales
      I18n.available_locales = [:en, :fr, :es]
      
      # Stub authorize for all tests in this context to focus on locale extraction
      allow(controller).to receive(:authorize).and_return(true)
    end

    after do
      I18n.available_locales = @original_locales
    end

    # Verifies that locale can be set directly via URL parameter
    # This allows users to explicitly choose their language preference
    it 'extracts locale from params' do
      get :index, params: { locale: 'fr' }
      expect(controller.send(:extract_locale)).to eq(:fr)
    end

    # Tests handling of invalid locale parameters
    # This ensures robustness when handling potentially malicious or malformed inputs
    it 'returns nil for invalid locales in params' do
      get :index, params: { locale: 'invalid' }
      expect(controller.send(:extract_locale)).to be_nil
    end

    # Verifies that browser language preferences are respected
    # This allows automatic language selection based on user browser settings
    it 'extracts first valid locale from Accept-Language header' do
      request.env['HTTP_ACCEPT_LANGUAGE'] = 'fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7'
      get :index
      expect(controller.send(:extract_locale)).to eq(:fr)
    end

    # Tests fallback to secondary browser language preferences
    # When the primary language isn't supported, should use the next one that is
    it 'extracts second valid locale from Accept-Language header if first is invalid' do
      request.env['HTTP_ACCEPT_LANGUAGE'] = 'de-DE,de;q=0.9,es-ES;q=0.8,es;q=0.7'
      get :index
      expect(controller.send(:extract_locale)).to eq(:es)
    end

    # Tests behavior when no supported languages are found in the header
    # Should return nil to allow fallback to default locale
    it 'returns nil when Accept-Language header contains no valid locales' do
      request.env['HTTP_ACCEPT_LANGUAGE'] = 'de-DE,de;q=0.9'
      get :index
      expect(controller.send(:extract_locale)).to be_nil
    end

    # Verifies robustness against empty headers
    # This handles the case where browsers send an empty Accept-Language header
    it 'handles empty Accept-Language headers gracefully' do
      request.env['HTTP_ACCEPT_LANGUAGE'] = ''
      get :index
      expect(controller.send(:extract_locale)).to be_nil
    end

    # Tests graceful handling of missing headers
    # Important for compatibility with clients that don't send language preferences
    it 'handles nil Accept-Language headers gracefully' do
      request.env.delete('HTTP_ACCEPT_LANGUAGE')
      get :index
      expect(controller.send(:extract_locale)).to be_nil
    end
  end

  # Tests the extraction of language codes from Accept-Language headers
  # This verifies correct parsing of the sometimes complex language preference strings
  describe 'language code extraction' do
    before do
      # Stub authorize for all tests in this context
      allow(controller).to receive(:authorize).and_return(true)
    end
    
    # Tests extraction from country-specific language codes (e.g., en-US)
    # Should correctly parse out just the language portion (en)
    it 'correctly extracts country-specific language codes' do
      request.env['HTTP_ACCEPT_LANGUAGE'] = 'en-US,en;q=0.9'
      expect(controller.send(:extract_locale)).to eq(:en)
    end

    # Tests handling of complex multi-part language preference headers
    # Should correctly prioritize and extract the highest-priority supported language
    it 'correctly handles multi-part language headers' do
      request.env['HTTP_ACCEPT_LANGUAGE'] = 'fr-CA,fr;q=0.9,en-US;q=0.8,en;q=0.7,es;q=0.6'
      expect(controller.send(:extract_locale)).to eq(:fr)
    end

    # Tests handling of quality factors in language preferences
    # Should respect the q-values when determining language priority
    it 'correctly handles language headers with quality factors' do
      I18n.available_locales = [:en, :fr, :es]
      request.env['HTTP_ACCEPT_LANGUAGE'] = 'de;q=1.0,fr;q=0.9,en;q=0.8'
      expect(controller.send(:extract_locale)).to eq(:fr)
    end
  end
end
