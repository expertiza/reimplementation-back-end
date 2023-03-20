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
      #resources :sign_up_sheets
      resources :sign_up_sheet do
        collection do
          get :load_all_selected_topics
          get :add_signup_topics
          get :add_signup_topics_staggered
          get :delete_signup
          get :list
          get :signup_topics
          get :signup
          get :sign_up
          get :show_team
          get :switch_original_topic_to_approved_suggested_topic
          get :team_details
          get :intelligent_sign_up
          get :intelligent_save
          get :signup_as_instructor
          get :delete_signup_as_instructor
          post :delete_all_topics_for_assignment
          post :signup_as_instructor_action
          post :set_priority
          post :save_topic_deadlines
          post :delete_all_selected_topics
        end
      end
    end
  end
end
