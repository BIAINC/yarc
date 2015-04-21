require "yarc/redis_storage"

module Yarc
  class PermanentStorage
    include RedisStorage

    def initialize(config)
      super(config, "Permanent")
    end

    def set(key, value)
      key = redis_key(key)
      columns = config.serializer.serialize(value)
      redis.hmset(key, *columns)
    end

    def get(key)
      key = redis_key(key)
      columns = redis.hgetall(key)
      columns.empty? ? nil : config.serializer.deserialize(columns)
    end

    def delete(key)
      key = redis_key(key)
      redis.del(key)
    end

    def release(key)
      # Just return actual key name.
      redis_key(key)
    end

    def migrate(key, destination_key)
      redis.rename(key, redis_key(destination_key))
    end
  end
end