module Yarc
  module IdGenerators
    class IntIdGenerator
      attr_reader(:redis)
      attr_reader(:namespace)

      def initialize(redis, namespace)
        raise(ArgumentError, "Redis cannot be nil!") if redis.nil?
        raise(ArgumentError, "Namespace cannot be blank!") if namespace.nil? || namespace.empty?
        @redis = redis
        @namespace = namespace
      end

      def get_unique_id
        redis.incr("#{namespace}:last_id")
      end
    end
  end
end