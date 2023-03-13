Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  namespace :api do
    namespace :v1 do
      resources :roles
      resources :users
      resources :assignments
      resources :questions do
        collection do
          get 'show/:id', to: 'questions#show', as: 'show'
        end
      end
      resources :questionnaires, except: [:index] do
        collection do
          get :view
          post 'copy/:id', to: 'questionnaires#copy', as: 'copy'
          post 'update/:id', to: 'questionnaires#update', as: 'update'
          delete 'delete/:id', to: 'questionnaires#delete', as: 'delete'
          get 'show/:id', to: 'questionnaires#show', as: 'show'
        end
      end
    end
  end


end
