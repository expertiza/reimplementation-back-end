Rails.application.routes.draw do
  resources :signed_up_teams
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
      #resources :sign_up_sheets
      resources :sign_up_sheet do
        collection do
          get :delete_signup
          get :sign_up
          get :delete_signup_as_instructor
          post :signup_as_instructor_action
        end
      end
      resources :sign_up_topics do
        collection do
          get :filter
          delete :filter, to: 'sign_up_topics#delete_filter'
          delete :delete_all_topics_for_assignment
          delete :delete_all_selected_topics
        end
      end
    end
  end
end
