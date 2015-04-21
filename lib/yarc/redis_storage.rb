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

    def keys
      pattern = "#{namespace}:*"
      redis.keys(pattern).map{|k| k[(namespace.size + 1)..-1]}
    end

    def add(object)
      key = config.id_generator.get_unique_id
      set(key, object)
      key
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