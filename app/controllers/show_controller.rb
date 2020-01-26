
class ShowController < ApplicationController
    def index
        @google_api_key = ENV["GOOGLE_API_KEY"]
        # 映画リストを取得
        @movieList = convert_movie_data
    end

    def convert_movie_data
        movie_array = []
        movie_result =  Movie.select(
                        :index,
                        :title,
                        :time,
                        :all_time,
                        :theater,
                        :latitude,
                        :longitude,
                        :link,
                        :description,
                        :poster_id,
                        :drop_path,
                        :review,
                        :release_date).distinct
        movie_result.each { |movie|
            movie_hash = {}
            time = get_time_diff(movie.time)
            # 2時間以内の映画のみ表示
            if time.blank? || time > 120 then
                next
            end

            movie_hash[:index] = movie.index
            movie_hash[:title] = movie.title
            movie_hash[:time] = time
            movie_hash[:all_time] = movie.all_time
            movie_hash[:theater] = movie.theater
            movie_hash[:latitude] = movie.latitude
            movie_hash[:longitude] = movie.longitude
            movie_hash[:link] = movie.link
            movie_hash[:description] = movie.description
            movie_hash[:poster_id] = movie.poster_id
            movie_hash[:drop_path] = movie.drop_path
            movie_hash[:review] = movie.review
            movie_hash[:release_date] = movie.release_date
            movie_array.push(movie_hash)
        }

        movie_array
    end

    def get_time_diff(movie_time)
        # タイムゾーンを設定
        Chronic.time_class = Time.zone
        # 現在時刻を取得
        current_time = Chronic.parse("now")
        # 現在時刻との差分を取得
        movie_time = Chronic.parse(movie_time)
        hhmm = (movie_time - current_time).to_i / 60
        return hhmm > 0 ? hhmm : nil
    end
end
