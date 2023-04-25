Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  namespace :api do
    namespace :v1 do
      resources :badges
      resources :duties
      resources :institutions
      resources :roles
      resources :users do
        get 'institution/:id', on: :collection, action: :institution_users
        get ':id/managed', on: :collection, action: :managed_users
      end
      resources :assignments
    end
  end
end
