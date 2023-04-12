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
      #added routes for signup topics
      # resources :sign_up_topics
      resources :sign_up_topics do
        collection do
          get :filter
          delete '/', to: 'sign_up_topics#destroy'
          # delete :filter, to: 'sign_up_topics#delete_filter'
          # delete :delete_all_topics_for_assignment
          # delete :delete_all_selected_topics
        end
      end
    end
  end
end
