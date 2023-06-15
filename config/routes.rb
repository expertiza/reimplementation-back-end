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
      
      resources :questionnaires do
        collection do
          post 'copy/:id', to: 'questionnaires#copy', as: 'copy'
          get 'toggle_access/:id', to: 'questionnaires#toggle_access', as: 'toggle_access'
        end
      end
      
      resources :questions do
        collection do
          get :types
          get 'show_all/questionnaire/:id', to:'questions#show_all#questionnaire', as: 'show_all'
          delete 'delete_all/questionnaire/:id', to:'questions#delete_all#questionnaire', as: 'delete_all'
        end
      end
      
      resources :signed_up_teams do
        collection do
          post '/sign_up', to: 'signed_up_teams#sign_up'
          post '/sign_up_student', to: 'signed_up_teams#sign_up_student'
        end
      end
      resources :sign_up_topics do
        collection do
          get :filter
          delete '/', to: 'sign_up_topics#destroy'
        end
      end
      
      resources :invitations do
        get 'user/:user_id/assignment/:assignment_id/', on: :collection, action: :invitations_for_user_assignment
      end
      
      resources :account_requests do
        collection do
          get :pending, action: :pending_requests
          get :processed, action: :processed_requests
        end
      end
    end
  end
end
