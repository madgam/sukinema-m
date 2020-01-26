Rails.application.routes.draw do
  get "/" => "show#index"
  get "/des" => "movie#get_movie"
  get "/ind" => "movie#index"
  resource :redis, only: %i[show]
end
