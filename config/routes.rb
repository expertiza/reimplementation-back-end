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

      resources :grades do
        collection do
          get ':id/view_team', action: :view_team
          get ':id/view', action: :view
          get ':id/view_scores', action: :view_scores
          put ':id/update', action: :update
          get ':id', action: :show
          # put ':id/edit', action: :edit
          get ':id/action_allowed', action: :action_allowed
          post ':id/save_grade_and_comment_for_submission', action: :save_grade_and_comment_for_submission
          # get ':id/redirect_when_disallowed', action: :redirect_when_disallowed
          # post ':id/assign_all_penalties', action: :assign_all_penalties
          # get ':id/instructor_review', action: :instructor_review
          # get :view
          # get :view_team
          # get :view_reviewer
          # get :view_my_scores
          # get :instructor_review
          # post :remove_hyperlink

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
