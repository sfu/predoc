Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get 'viewer' => 'documents#view'
  get 'convert' => 'documents#convert'

  get 'status' => 'status#index'

end
