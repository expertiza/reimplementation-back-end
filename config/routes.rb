Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  namespace :api do
    namespace :v1 do
      resources :roles
      resources :users
      resources :assignments
      resources :participants, only: [:destroy] do
        collection do
          get 'index/:model/:id', to: 'participants#index'
          post ':model/:id/:authorization', to: 'participants#create'
          post 'change_handle/:id', to: 'participants#update_handle'
          post 'update_authorizations/:id/:authorization', to: 'participants#update_authorizations'
          get 'inherit/:id', to: 'participants#inherit'
          get 'bequeath/:id', to: 'participants#bequeath'
        end
      end
    end
  end
end
