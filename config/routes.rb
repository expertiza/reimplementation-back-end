Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  namespace :api do
    namespace :v1 do
      resources :roles
      resources :users
      resources :assignments
      resources :questions
      resources :questionnaires, only: %i[new create edit update] do
        collection do
          get 'copy/:id', to: 'questionnaires#copy', as: 'copy'
          # get :select_questionnaire_type
          # post :select_questionnaire_type
          get :toggle_access
          get 'show/:id' to: 'questionnaires#show' as: 'show'
          get :view
          post :save_all_questions
          get :delete
          post :create_questionnaire
        end  
      end
    end
  end


end
