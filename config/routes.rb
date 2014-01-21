StatementConverter::Application.routes.draw do
  resources :cards do
    member do
      get :download
      post :download_file
    end
  end

  root :to => 'cards#index'
end
