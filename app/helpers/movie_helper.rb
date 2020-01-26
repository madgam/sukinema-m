module MovieHelper
    def get_search_movie_uri(title_nm)
        api_key = ENV["TMDB_API_KEY"]
        base_url = "https://api.themoviedb.org/3/search/movie"
        params = {
            "api_key" => api_key,
            "language" => "ja-JP",
            "query" => title_nm,
            "page" => "1",
            "include_adult" => "false"
        }
        url = base_url + "?" + URI.encode_www_form(params)

        url
    end

    module_function :get_search_movie_uri
end
