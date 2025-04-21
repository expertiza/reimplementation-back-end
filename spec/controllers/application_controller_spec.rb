require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  controller(ActionController::API) do
    before_action :set_locale
    def index; head :ok; end
  end

  it 'uses params[:locale] when valid' do
    get :index, params: { locale: 'fr' }
    expect(I18n.locale).to eq(:fr)
  end

  it 'falls back to Accept-Language header' do
    request.headers['Accept-Language'] = 'es-ES,es;q=0.9'
    get :index
    expect(I18n.locale).to eq(:es)
  end

  it 'defaults on unknown locale' do
    get :index, params: { locale: 'xx' }
    expect(I18n.locale).to eq(I18n.default_locale)
  end
end
