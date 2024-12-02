Rails.application.routes.draw do

  mount Rswag::Api::Engine => 'api-docs'
  mount Rswag::Ui::Engine => 'api-docs'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  post '/login', to: 'authentication#login'
  namespace :api do
    namespace :v1 do
      resources :institutions
      resources :roles do
        collection do
          # Get all roles that are subordinate to a role of a logged in user
          get 'subordinate_roles', action: :subordinate_roles
        end
      end
      resources :users do
        collection do
          get 'institution/:id', action: :institution_users
          get ':id/managed', action: :managed_users
          get 'role/:name', action: :role_users
        end
      end
      resources :assignments do
        collection do
          post '/:assignment_id/add_participant/:user_id',action: :add_participant
          delete '/:assignment_id/remove_participant/:user_id',action: :remove_participant
          patch '/:assignment_id/remove_assignment_from_course',action: :remove_assignment_from_course
          patch '/:assignment_id/assign_course/:course_id',action: :assign_course
          post '/:assignment_id/copy_assignment', action: :copy_assignment
          get '/:assignment_id/has_topics',action: :has_topics
          get '/:assignment_id/show_assignment_details',action: :show_assignment_details
          get '/:assignment_id/team_assignment', action: :team_assignment
          get '/:assignment_id/has_teams', action: :has_teams
          get '/:assignment_id/valid_num_review/:review_type', action: :valid_num_review
          get '/:assignment_id/varying_rubrics_by_round', action: :varying_rubrics_by_round?
          post '/:assignment_id/create_node',action: :create_node
        end
      end

      resources :bookmarks, except: [:new, :edit] do
        member do
          get 'bookmarkratings', to: 'bookmarks#get_bookmark_rating_score'
          post 'bookmarkratings', to: 'bookmarks#save_bookmark_rating_score'
        end
      end
      resources :student_tasks do
        collection do
          get :list, action: :list
          get :view
        end
      end

      resources :courses do
        collection do
          get ':id/add_ta/:ta_id', action: :add_ta
          get ':id/tas', action: :view_tas
          get ':id/remove_ta/:ta_id', action: :remove_ta
          get ':id/copy', action: :copy
        end
      end

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

      resources :join_team_requests do
        collection do
          post 'decline/:id', to:'join_team_requests#decline'
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

      resources :participants do
        collection do
          get '/user/:user_id', to: 'participants#index'
          get '/assignment/:assignment_id', to: 'participants#index'
          get '/:id', to: 'participants#show'
          post '/:authorization', to: 'participants#add'
          patch '/:id/:authorization', to: 'participants#update_authorization'
          delete '/:id', to: 'participants#destroy'
        end
      end
    end
  end
end