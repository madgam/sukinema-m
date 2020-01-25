Rails.application.routes.draw do
  get "/" => "show#index"
  get "/des" => "movie#get_movie"
end
