Rails.application.routes.draw do
  namespace :api do
    resources :outpatients, only: %i[index update], constraints: { id: /[1-9][0-9]*/ }
    get "csrf", to: "patients#csrf"
    post "sql-query", to: "sql_queries#create" if Rails.env.development? || Rails.env.test?
    get "db-schema", to: "sql_schemas#show" if Rails.env.development? || Rails.env.test?
    resources :patients, only: %i[index show create update], constraints: { id: /[1-9][0-9]*/ } do
      get :reception_candidates, on: :member, controller: "receptions"
    end
    resources :receptions, only: :create
    resources :departments, only: %i[index show create update], constraints: { id: /[1-9][0-9]*/ }
    resources :occupations, only: %i[index show create update], constraints: { id: /[1-9][0-9]*/ }
    resources :users, only: %i[index show create update], constraints: { id: /[1-9][0-9]*/ }
  end
end
