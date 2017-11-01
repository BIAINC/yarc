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

    def release(key)
      # Just return actual key name; nothing else to do here
      redis_key(key)
    end

    def migrate(redis_key_name, new_key, must_exist = true)
      with_checked_existence(must_exist) do
        redis.rename(redis_key_name, redis_key(new_key))
      end
    end
  end
end
