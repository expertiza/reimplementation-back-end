Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  namespace :api do
    namespace :v1 do
      get 'badges/index'
      get 'badges/show'
      get 'badges/create'
      get 'badges/update'
      get 'badges/destroy'
      get 'duties/index'
      get 'duties/show'
      get 'duties/create'
      get 'duties/update'
      get 'duties/destroy'
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
