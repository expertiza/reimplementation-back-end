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
        member do
          post '/add_ta' => 'courses#add_ta'
          get '/tas' => 'courses#view_tas'
          post '/remove_ta/:ta_id' => 'courses#remove_ta'
          get '/copy' =>'courses#copy'
        end
      end
    end
  end
end
