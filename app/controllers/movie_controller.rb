require "nokogiri"
require "open-uri"
require "date"
require "net/http"
require "uri"
require "json"
require "openssl"
require 'geocoder'
require 'resolv'
require 'geocode_controller.rb'
require 'open_uri_redirections'

class MovieController < ApplicationController

  def index
    MovieJob.perform_later
  end

  def get_movie 
    @user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.81 Safari/537.36"
    today = Time.now.strftime("%Y%m%d")

    page = 1
    index = 1
    movies = []

    # GeoCodeクラスを初期化
    @yahoo_app_id = ENV["YAHOO_APP_ID"]
    yahoo_geocoder = GeocodeController.new("#{@yahoo_app_id}")

    Movie.delete_all

    while true do
      
      if index > 500 then
        break
      end
      url = "https://eigakan.org/theaters/pref/13/#{today}/#{page}"
      charset = nil
      begin
        html = open(url, "User-Agent" => @user_agent) do |f|
          charset = f.charset
          f.read
        end
      rescue OpenURI::HTTPError => e
        # 例外処理
        false
      end

      
      node = Nokogiri::HTML.parse(html, nil, charset)
      
      # 映画情報が存在しない場合は処理終了
      if node.css(".mj03").inner_text.include?("存在しません。") then
        break
      end
      
      # 作品名を取得
      node.css(".theaterlist01").children.each{ |mv|

        if index > 500 then
          break
        end

        # DB登録用のモデルオブジェクトを生成
        @movie_model = Movie.new()

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

          # DB登録用のモデルオブジェクトを初期化
          @movie_model = Movie.new()

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
            editedId = id.slice(1, id.length - 2)
            detailUrl = "https://eigakan.org/movies/detail/#{editedId}"
            
            begin
              childhtml = open(detailUrl, "User-Agent" => @user_agent) do |f|
                  charset = f.charset
                  f.read
              end
            rescue OpenURI::HTTPError => e
              # 例外処理
              false
            end
            
            childnode = Nokogiri::HTML.parse(childhtml, nil, charset)
            description = childnode.css(".j2").inner_text.split("公開")[1].split("\n")[0]
            
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

            @movie_model.index = index
            @movie_model.title = @title_nm + title_option
            @movie_model.time = edit_str_strip[0].gsub(/[[:space:]]/, '')
            @movie_model.all_time = all_time
            @movie_model.theater = theater
            @movie_model.latitude = lat_long["latitude"]
            @movie_model.longitude = lat_long["longitude"]
            @movie_model.link = link
            @movie_model.description = description
            get_movie_data
          end

          begin
            @movie_model.save
          rescue
            # 例外の場合は何もしない
          end
          index += 1
        }
      }
      page += 1
    end
  end

  def get_movie_data

    access_token = ENV["TMDB_ACCESS_TOKEN"]
    
    search_url = ""
    search_id = ""
    p_path = ""
    review = 0.0
    release_date = ""
    search_uri = MovieHelper.get_search_movie_uri(@title_nm)

    search_charset = nil
    p search_uri
    json = open(search_uri, :allow_redirections => :all, "User-Agent" => @user_agent) do |f|
      search_charset = f.charset
      JSON.parse(f.read)
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
      
      review = result["vote_average"]
      review = review / 2
      release_date = result["release_date"]
      
      if p_path.blank? then
        drop_path = nil
      else
        @movie_model.poster_id = result["poster_path"]
        @movie_model.drop_path = "https://image.tmdb.org/t/p/w1000_and_h563_face#{drop_path}"
      end
    end

    # レビュー
    @movie_model.review = review.to_f.round(1)
    # 公開日
    @movie_model.release_date = release_date.gsub("-",".")
  end
end