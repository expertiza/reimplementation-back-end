Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  namespace :api do
    namespace :v1 do
      resources :institutions
      resources :roles
      resources :users do
        get 'institution/:id', on: :collection, action: :institution_users
        get ':id/managed', on: :collection, action: :managed_users
      end
      resources :assignments
      resources :courses do
        collection do
          get ':id/add_ta/:ta_id', action: :add_ta
          get ':id/tas', action: :view_tas
          get ':id/remove_ta/:ta_id', action: :remove_ta
          get ':id/copy', action: :copy
        end
      end
    end
  end
end
