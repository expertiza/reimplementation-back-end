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
      resources :responses, only: %i[new create edit update] do
        collection do
          get :new_feedback
          get :view
          get :remove_hyperlink
          get :save
          get :redirect
          get :show_calibration_results_for_student
          post :custom_create
          get :json
          post :send_email
          get :author
          get :run_get_notification
          post :edit
          post :delete
        end
      end
    end
  end
end
