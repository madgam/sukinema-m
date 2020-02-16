require "nokogiri"
require "open-uri"
require "date"
require "net/http"
require "uri"
require "json"
require "openssl"
require 'geocoder'
require 'resolv'
require 'open_uri_redirections'

desc "movie load automation"
task :update_all_movies => :environment do
    @user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.81 Safari/537.36"
    today_yyyymmdd = Time.now.strftime("%Y%m%d")

    page = 1
    index = 1
    movies = []

    while true do
        eigakan_uri = "https://eigakan.org/theaters/pref/13/#{today_yyyymmdd}/#{page}"
        charset = nil
        begin
            eigakan_html = open(eigakan_uri, "User-Agent" => @user_agent) do |f|
                charset = f.charset
                f.read
            end
        rescue => e
            # 例外処理
            puts e
            nil
        end

        node = Nokogiri::HTML.parse(eigakan_html, nil, charset)

        # 映画情報が存在しない場合は処理終了
        if node.css(".mj03").inner_text.include?("存在しません。") then
            break
        end

        # 作品名を取得
        node.css(".theaterlist01").children.each{ |movie_data|

            # ブランクの場合はスキップ
            if movie_data.css("td").inner_text.blank? then
                next
            end

            if "映画館名" == movie_data.parent.css(".thater_check02").inner_text then
                next
            end

            # 上映時間を配列化
            start_time = movie_data.css("td").inner_text.split(" / ")
            # 全上映時間を取得
            all_time = movie_data.css("td").inner_text.split("～終")[0].gsub(movie_data.css("a").inner_text,"")

            # 上映時間が無い、純粋なタイトルのみの場合はスキップ
            if movie_data.css("a").inner_text.blank? then
                next
            end

            # 上映時間を取得
            start_time.each{ |node_time|
                
                if node_time.include?(":") then
                    node_time = node_time.split("～終")[0]
                    if node_time.include?(movie_data.css("a").inner_text) then
                        node_time = node_time.gsub(movie_data.css("a").inner_text, "")
                        if node_time.length == 0 then
                            next
                        end
                    end
                    splited_node_time = node_time.split("※")
                    
                    movie_id = movie_data.css("a")[0][:href].split(",")[1].gsub("/movies/detail/","")
                    movie_id = movie_id.slice(1, movie_id.length - 2)
                    movie_detail_uri = "https://eigakan.org/movies/detail/#{movie_id}"
                    
                    begin
                        movie_detail_html = open(movie_detail_uri, "User-Agent" => @user_agent) do |f|
                            charset = f.charset
                            f.read
                        end
                    rescue => e
                        # 例外処理
                        puts e
                        nil
                    end
                    
                    movie_detail_node = Nokogiri::HTML.parse(movie_detail_html, nil, charset)
                    description = movie_detail_node.css(".j2").inner_text.split("公開")[1].split("\n")[0]
                    
                    title_nm = movie_data.css("a").inner_text.gsub("(","（").gsub(")","）")
                    title_option = ""
                    if title_nm.include?("字幕") || title_nm.include?("吹替") then
                        title_ary = title_nm.split("（")
                        title_option = "（" + title_ary[title_ary.length - 1]
                        title_nm = title_nm.gsub(title_option, "")
                    end
                    theater_block = movie_data.parent.css(".thater_check02")
                    # 映画館を取得
                    theater = theater_block.inner_text.split("　(")[0]
                    google_api_result = Geocoder.coordinates(theater)
                    lat_long = {'latitude' => google_api_result[0], 'longitude' => google_api_result[1]}
                    # 映画館のリンク
                    link = theater_block.css("a")[0][:href]

                    search_id = ""
                    p_path = ""
                    poster_id = ""
                    drop_path = ""
                    review = 0.0
                    release_date = ""
                    
                    api_key = ENV["TMDB_API_KEY"]
                    base_uri = "https://api.themoviedb.org/3/search/movie"
                    params = {
                        "api_key" => api_key,
                        "language" => "ja-JP",
                        "query" => title_nm,
                        "page" => "1",
                        "include_adult" => "false"
                    }
                    search_uri = base_uri + "?" + URI.encode_www_form(params)
                    
                    search_charset = nil
                    begin
                        tmdb_results = open(search_uri, "User-Agent" => @user_agent) do |f|
                            search_charset = f.charset
                            JSON.parse(f.read)
                        end
                    rescue => e
                        # 例外処理
                        puts e
                        nil
                    end
                    
                    tmdb_result = tmdb_results['results']
                    
                    if tmdb_result != nil && tmdb_result.length != 0 then
                        tmdb_result = tmdb_result.sort_by { |hash| -(hash['release_date'].to_i) }
                        tmdb_movie_detail = tmdb_result[0]
                        
                        drop_path = tmdb_movie_detail["backdrop_path"]
                        p_path = tmdb_movie_detail["poster_path"]
                        if drop_path.blank? then
                            drop_path = tmdb_movie_detail["poster_path"]
                        end
                        
                        review = (tmdb_movie_detail["vote_average"] / 2).to_f.round(1)
                        release_date = tmdb_movie_detail["release_date"].gsub("-",".")
                        
                        if !p_path.blank? then
                            poster_id = tmdb_movie_detail["poster_path"]
                        end
                    end

                    movies << Movie.new(
                        index: index,
                        title: title_nm + title_option,
                        time: splited_node_time[0].gsub(/[[:space:]]/, ''),
                        all_time: all_time,
                        theater: theater,
                        latitude: lat_long["latitude"],
                        longitude: lat_long["longitude"],
                        link: link,
                        description: description,
                        poster_id: poster_id,
                        drop_path: drop_path,
                        review: review,
                        release_date: release_date
                    )
                end
                index += 1
            }
        }
        page += 1
    end

    Movie.delete_all
    Movie.import movies
end