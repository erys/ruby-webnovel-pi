# == Route Map
#

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  root 'books#index'

  resources :books, param: :short_name do
    resources :chapters, param: :ch_number do
      get :clean, on: :collection
    end
    resources :corrupt_chapters, only: [:new, :create, :update, :edit] do
      patch :undo, on: :member
    end
  end
end
