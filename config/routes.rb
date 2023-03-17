Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  namespace :api do
    namespace :v1 do
      resources :roles
      resources :users
      resources :assignments
      resources :questionnaires do
        collection do
          post 'copy/:id', to: 'questionnaires#copy', as: 'copy'
          get 'toggle_access/:id', to: 'questionnaires#toggle_access', as: 'toggle_access'
        end
      end
      resources :questions do
        collection do
          get :types
        end
      end
    end
  end
end
