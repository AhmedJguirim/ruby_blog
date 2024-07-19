Rails.application.routes.draw do
  get 'profiles/show'
  get 'criticisms/create'
  get 'criticisms/destroy'
  # https://stackoverflow.com/questions/3546289/override-devise-registrations-controller
  devise_for :users, controllers: { registrations: 'users/registrations' }
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  authenticated :user do
    root 'articles#index', as: :authenticated_root
  end

  #https://stackoverflow.com/questions/4954876/setting-devise-login-to-be-root-page
  devise_scope :user do
    root to: "devise/sessions#new"
  end


  get 'profiles/:id', to: 'profiles#show', as: 'profile'

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
