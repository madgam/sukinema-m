class ResqueSample
  @queue = :resque_sample

  class << self
    def perform(message)
      puts message
    end

    def self.perform_async(message)
      Resque.enqueue(self, message)
    end
  end
end