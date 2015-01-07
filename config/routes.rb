Rails.application.routes.draw do
  mount Krikri::Engine => '/krikri'
  root :to => "catalog#index"
  blacklight_for :catalog
  devise_for :users
end
