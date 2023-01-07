# frozen_string_literal: true

# == Route Map
#

Rails.application.routes.draw do
  post 'backup/generate', to: 'backup#generate'

  namespace :api do
    resources :original_chapters, only: %i[create]
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  root 'books#index'

  resources :books, param: :short_name do
    post :backup, on: :member
    post :restore, on: :collection
    resources :chapters, param: :ch_number do
      get :clean, on: :collection
    end
    resources :corrupt_chapters, only: %i[new create update edit] do
      patch :undo, on: :member
    end
  end

  # TODO: #2 author pages
  # TODO: #3 auth required routes
  # TODO: #4 search ability
  # TODO: #5 way to export data into some format
  #   (zip with chinese/english chapters in txt files and csv of all author/book/chapter metadata)
  #   Don't export character frequency stuff
  # TODO: #6 user reading history/progress
end
