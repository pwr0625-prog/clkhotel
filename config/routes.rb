Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "welcome#index"
  get "design", to: "welcome#design"

  get "signup", to: "users#new"
  post "signup", to: "users#create"
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  resources :users, only: %i[show]
  resources :properties, only: %i[index show]

  resources :bookings, only: %i[create show] do
    collection do
      get :my
    end

    member do
      patch :cancel
      patch :complete
      resource :payment, only: %i[new create]
      resource :review, only: %i[create]
    end
  end

  resources :wishlists, only: %i[create destroy]

  namespace :host do
    root "dashboard#index"
    get "bookings", to: "dashboard#bookings"
    get "bookings/:id/confirm", to: "dashboard#confirm_form", as: :confirm_booking_form
    patch "bookings/:id/confirm", to: "dashboard#confirm", as: :confirm_booking
    patch "bookings/:id/reject", to: "dashboard#reject", as: :reject_booking
    delete "bookings/:id", to: "dashboard#destroy", as: :delete_booking

    resources :properties do
      member do
        post :room_types, to: "properties#create_room_type"
      end

      resource :image, only: %i[create], controller: "property_images"
    end

    resources :room_types, only: %i[edit update] do
      resource :inventory, only: %i[show update], controller: "room_inventories"
    end
    resources :room_types, only: [] do
      resources :images, controller: "room_type_images", only: %i[create update destroy]
      patch "images/:image_id/move_up", to: "room_type_images#move_up", as: :move_up_image
      patch "images/:image_id/move_down", to: "room_type_images#move_down", as: :move_down_image
      patch "images/:image_id/make_thumbnail", to: "room_type_images#make_thumbnail", as: :make_thumbnail_image
    end
  end
end
