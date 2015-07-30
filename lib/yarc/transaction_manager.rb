module Yarc
  class TransactionManager
    def initialize(redis)
      @redis = redis
    end

    def in_transaction(*args, &block)
      @redis.multi(&block)
    rescue Transaction::Discard
      # Do nothing.
    end
  end
end
