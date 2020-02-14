Rails.application.routes.draw do
  get "/" => "show#index"
  get "/api" => "show#api"
end
