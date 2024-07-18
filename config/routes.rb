Rails.application.routes.draw do
  get 'criticisms/create'
  get 'criticisms/destroy'
  # https://stackoverflow.com/questions/3546289/override-devise-registrations-controller
  devise_for :users, controllers: { registrations: 'users/registrations' }
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root 'articles#index'

  resources :articles do
    resources :documents, only: [:create, :destroy]
    member do
      post 'upvote'
      post 'downvote'
    end
    resources :comments do
      resources :criticisms, only: [:create, :destroy]
      resources :documents 
      member do
        post 'upvote'
        post 'downvote'
      end
    
  end
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
