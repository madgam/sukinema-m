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

desc "This task is called by the Heroku scheduler add-on"
task :update_all_movies => :environment do
    @user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.81 Safari/537.36"
    today_yyyymmdd = Time.now.strftime("%Y%m%d")

    page = 1
    index = 1
    movies = []

    Movie.delete_all

    while true do
        eigakan_uri = "https://eigakan.org/theaters/pref/13/#{today_yyyymmdd}/#{page}"
        charset = nil
        begin
            html = open(eigakan_uri, "User-Agent" => @user_agent) do |f|
                charset = f.charset
                f.read
            end
        rescue => e
            # 例外処理
            puts e
            nil
        end

        node = Nokogiri::HTML.parse(html, nil, charset)

        # 映画情報が存在しない場合は処理終了
        if node.css(".mj03").inner_text.include?("存在しません。") then
            break
        end

        # 作品名を取得
        node.css(".theaterlist01").children.each{ |mv|

            if index > 10 then
                break
            end

            # ブランクの場合はスキップ
            if mv.css("td").inner_text.blank? then
                next
            end

            if "映画館名" == mv.parent.css(".thater_check02").inner_text then
                next
            end

            # 文字列を配列化
            ary = mv.css("td").inner_text.split(" / ")
            # 全上映時間を取得
            all_time = mv.css("td").inner_text.split("～終")[0].gsub(mv.css("a").inner_text,"")

            # 上映時間が無い、純粋なタイトルのみの場合はスキップ
            if mv.css("a").inner_text.blank? then
                next
            end

            # 上映時間を取得
            ary.each{ |elm|
                
                if elm.include?(":") then
                    edit_str = elm.split("～終")[0]
                    if edit_str.include?(mv.css("a").inner_text) then
                        edit_str = edit_str.gsub(mv.css("a").inner_text, "")
                        if edit_str.length == 0 then
                        next
                        end
                    end
                    edit_str_strip = edit_str.split("※")
                    
                    id = mv.css("a")[0][:href].split(",")[1].gsub("/movies/detail/","")
                    edited_id = id.slice(1, id.length - 2)
                    movie_detail_uri = "https://eigakan.org/movies/detail/#{edited_id}"
                    
                    begin
                        child_html = open(movie_detail_uri, "User-Agent" => @user_agent) do |f|
                            charset = f.charset
                            f.read
                        end
                    rescue => e
                        # 例外処理
                        puts e
                        nil
                    end
                    
                    child_node = Nokogiri::HTML.parse(child_html, nil, charset)
                    description = child_node.css(".j2").inner_text.split("公開")[1].split("\n")[0]
                    
                    edit_title = mv.css("a").inner_text.gsub("(","（").gsub(")","）")
                    @title_nm = edit_title
                    title_option = ""
                    if edit_title.include?("字幕") || edit_title.include?("吹替") then
                        title_ary = edit_title.split("（")
                        title_option = "（" + title_ary[title_ary.length - 1]
                        @title_nm = edit_title.gsub(title_option, "")
                    end
                    theater_block = mv.parent.css(".thater_check02")
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
                    base_url = "https://api.themoviedb.org/3/search/movie"
                    params = {
                        "api_key" => api_key,
                        "language" => "ja-JP",
                        "query" => @title_nm,
                        "page" => "1",
                        "include_adult" => "false"
                    }
                    search_uri = base_url + "?" + URI.encode_www_form(params)
                    
                    search_charset = nil
                    begin
                        json = open(search_uri, "User-Agent" => @user_agent) do |f|
                            search_charset = f.charset
                            JSON.parse(f.read)
                        end
                    rescue => e
                        # 例外処理
                        puts e
                        nil
                    end
                    
                    search_result = json['results']
                    
                    if search_result != nil && search_result.length != 0 then
                        search_result = search_result.sort_by { |hash| -(hash['release_date'].to_i) }
                        result = search_result[0]
                        
                        drop_path = result["backdrop_path"]
                        p_path = result["poster_path"]
                        if drop_path.blank? then
                            drop_path = result["poster_path"]
                        end
                        
                        review = (result["vote_average"] / 2).to_f.round(1)
                        release_date = result["release_date"].gsub("-",".")
                        
                        if !p_path.blank? then
                            poster_id = result["poster_path"]
                            drop_path = "https://image.tmdb.org/t/p/w1000_and_h563_face#{drop_path}"
                        end
                    end

                    movies << Movie.new(
                        index: index,
                        title: @title_nm + title_option,
                        time: edit_str_strip[0].gsub(/[[:space:]]/, ''),
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

    Movie.import movies
end