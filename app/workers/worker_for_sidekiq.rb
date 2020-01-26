class WorkerForSidekiq
  include Sidekiq::Worker
  sidekiq_options queue: :sidekiq
  def perform(text)
    sleep 5
    p "sidekiq: #{text}"
  end

# ActiveRecord を扱う場合など、引数で全情報を与える必要がある
# def perform(id, text)
#   hoge = Hoge.find(id)
#   hoge.update_attributes({text: text})
# end
end