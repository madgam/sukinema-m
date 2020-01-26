class RedisController < ApplicationController
  def show
    Redis.current.set('mykey', 'Hello')
  end
end