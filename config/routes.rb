StatementConverter::Application.routes.draw do

  resources :statements do
 	 collection do 
  		post :upload_file
 	 end

  end

  root :to => 'statements#index'
end
