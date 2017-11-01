module Yarc
  module RedisStorage
    attr_reader :config, :namespace

    def initialize(config, namespace)
      raise(ArgumentError, "Config cannot be nil!") if config.nil?
      raise(ArgumentError, "Namespace cannot be empty!") if namespace.nil? || namespace.empty?
      @config = config
      @namespace = "#{config.namespace}:#{namespace}"
    end

    def keys(prefix = "")
      pattern = "#{namespace}:#{prefix}*"
      redis.keys(pattern).map{|k| k[(namespace.size + 1)..-1]}
    end

    def add(object)
      key = config.id_generator.get_unique_id
      set(key, object)
      key
    end

    def delete(*keys)
      keys = keys.flatten.map{|k| redis_key(k)}
      redis.del(keys)
    end

    def exists?(key)
      redis.exists(redis_key(key))
    end

    def watch(key, *keys)
      keys = ([key] + keys).flatten
      redis.watch(*keys)
    end

    def send_to(key, other_storage, must_exist)
      full_key = redis_key(key)
      other_storage.migrate(full_key, key, must_exist)
    end

    def with_checked_existence(must_exist, &block)
      block.call
    rescue Redis::CommandError => e
      # yep, redis doesn't give exception types
      raise unless /no such key/ =~ e.message
      raise if must_exist
      nil
    end

    private

    def redis
      config.redis
    end

    def redis_key(key)
      "#{namespace}:#{key}"
    end
  end
end
