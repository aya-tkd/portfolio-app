Rails.application.routes.draw do
  namespace :api do
    get "csrf", to: "patients#csrf"
    resources :patients, only: %i[show create update], constraints: { id: /[1-9][0-9]*/ }
  end
end
