Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get 'keyboard' => 'messages#keyboard'
  post 'message' => 'messages#message'
  delete 'chat_room/:user_key' => 'messages#delete'

  get 'users/new' => "users#new", as: :new_user
  post "users/:id" => "users#update"
  get 'users/:id/destroy' => "users#destroy", as: :delete_user
  resources "users"
  get 'users/:id/edit' => "users#edit", as: :edit_user

  get 'stores/new' => "stores#new", as: :new_store
  post "stores/:id" => "stores#update"
  get 'stores/:id/destroy' => "stores#destroy", as: :delete_store
  resources :stores do
    resources :drinks
    get 'drinks/:id/destroy' => "drinks#destroy", as: :delete_drink
  end
  get 'stores/:id/edit' => "stores#edit", as: :edit_store

end
