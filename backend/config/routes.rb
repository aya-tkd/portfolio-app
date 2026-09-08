Rails.application.routes.draw do
  namespace :api do
    get "csrf", to: "patients#csrf"
    post "sql-query", to: "sql_queries#create" if Rails.env.development? || Rails.env.test?
    resources :patients, only: %i[show create update], constraints: { id: /[1-9][0-9]*/ }
  end
end
