# config/routes.rb
Rails.application.routes.draw do
  get  '/auth/google_oauth2/callback', to: 'api/v1/omniauth_callbacks#google_oauth2'
  get  '/auth/failure',                to: 'api/v1/omniauth_callbacks#failure'
  get '/api/v1/me',                    to: 'api/v1/users#me'
  delete '/api/v1/sign_out',           to: 'api/v1/sessions#destroy'

  namespace :api do
    resources :features, only: [:index, :create, :destroy] do
      post 'run_all', on: :member
    end
    resources :record_tests, only: [:index, :create] do
      member do
        post 'vnc_url'
        post 'script_content'
      end
    end
    get 'test_runs/any_running', to: 'test_runs#any_running'
    resources :import_tests, only: [:create]
    resources :tests do
      get  'script',  to: 'tests#script',        on: :member
      post 'vnc_url', to: 'tests#update_vnc_url', on: :member
      resources :test_runs, only: [:index, :create, :show] do
        post 'artifacts', to: 'test_runs#receive_artifacts', on: :member
        post 'vnc_url',   to: 'test_runs#update_vnc_url',    on: :member
      end
    end
  end
end