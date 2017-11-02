require "yarc/redis_storage"

module Yarc
  class TemporaryStorage
    include RedisStorage

    def initialize(config)
      super(config, "Temporary")
    end

    def set(key, value)
      with_expiring_key(key) do |key|
        redis.hmset(key, *config.serializer.serialize(value))
      end
    end

    def get(key)
      columns = with_expiring_key(key) do |key|
        redis.hgetall(key)
      end.first
      columns.empty? ? nil : config.serializer.deserialize(columns)
    end

    def extend_ttl(key)
      redis.expire(redis_key(key), config.temporary_item_ttl)
    end

    def release(key)
      rk = redis_key(key)
      redis.persist(rk) == 0 ? nil : rk
    end

    def migrate(redis_key_name, new_key, must_exist = true)
      new_redis_key = redis_key(new_key)
      with_checked_existence(must_exist) do
        config.transaction_manager.in_transaction do
          redis.rename(redis_key_name, new_redis_key)
          redis.expire(new_redis_key, config.temporary_item_ttl)
        end
      end
    end

    private

    def with_expiring_key(key, *args, &block)
      key = redis_key(key)
      config.transaction_manager.in_transaction do
        block.call(key, *args)
        redis.expire(key, config.temporary_item_ttl)
      end
    end
  end
end
