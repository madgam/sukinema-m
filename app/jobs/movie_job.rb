class MovieJob < ApplicationJob
  queue_as :default

  def perform(instance)
    # Do something later
    p "Process #{instance}"
  end
end
