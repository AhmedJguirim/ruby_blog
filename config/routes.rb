Rails.application.routes.draw do
  # https://stackoverflow.com/questions/3546289/override-devise-registrations-controller
  devise_for :users, controllers: { registrations: 'users/registrations' }
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root 'articles#index'
  resources :articles do
    resources :comments
  end
  get 'tags/search', to: 'tags#index'
  namespace :api do
    namespace :v1 do 
      devise_scope :user do
        post 'login', to: 'sessions#create'
        delete 'logout', to: 'sessions#destroy'
      end
      resources :articles
      resources :comments

    end
  end
end
