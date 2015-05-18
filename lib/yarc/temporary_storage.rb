require "yarc/redis_storage"

module Yarc
  class TemporaryStorage
    include RedisStorage

    def initialize(config)
      super(config, "Temporary")
    end

    def set(key, value)
      with_expiring_key(key) do |key|
        redis.hmset(key, config.serializer.serialize(value))
      end
    end

    def get(key)
      columns = with_expiring_key(key) do |key|
        redis.hgetall(key)
      end.first
      columns.empty? ? nil : config.serializer.deserialize(columns)
    end

    def extend(key)
      redis.expire(redis_key(key), config.temporary_item_ttl)
    end

    def release(key)
      key = redis_key(key)
      redis.persist(key)
      key
    end

    def migrate(key, destination_key)
      new_key = redis_key(destination_key)
      redis.rename(key, new_key)
      redis.expire(new_key, config.temporary_item_ttl)
    end

    private

    def with_expiring_key(key, *args, &block)
      key = redis_key(key)
      redis.multi do
        block.call(key, *args)
        redis.expire(key, config.temporary_item_ttl)
      end
    end
  end
end