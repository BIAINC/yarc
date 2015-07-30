module Yarc
  module RedisStorage
    attr_reader(:config)
    attr_reader(:namespace)

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

    private

    def redis
      config.redis
    end

    def redis_key(key)
      "#{namespace}:#{key}"
    end
  end
end