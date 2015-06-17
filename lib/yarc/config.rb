require "redis"
require "yarc/serializers/multi_json_column_serializer"
require "yarc/id_generators/int_id_generator"

module Yarc
  class Config
    attr_reader(:namespace)

    def initialize(namespace, attributes = {})
      raise(ArgumentError, "Namespace cannot be blank!") if namespace.nil? || namespace.empty?
      @namespace = namespace

      self.redis = Redis.new(attributes[:redis]) if attributes.has_key?(:redis)
      self.temporary_item_ttl = attributes[:temporary_item_ttl] if attributes.has_key?(:temporary_item_ttl)
    end

    def redis
      @redis ||= Redis.new
    end

    def redis=(value)
      raise(ArgumentError, "Redis cannot be nil!") if value.nil?
      @redis = value
    end

    def temporary_item_ttl
      @temporary_item_ttl || 1800
    end

    def temporary_item_ttl=(value)
      raise(ArgumentError, "ttl is not a number!") unless value.respond_to?(:to_i)
      value = value.to_i
      raise(ArgumentError, "ttl is not greater than zero!") unless value > 0
      @temporary_item_ttl = value
    end

    def serializer
      @serializer ||= Serializers::MultiJsonColumnSerializer.new
    end

    def serializer=(value)
      raise(ArgumentError, "Serializer cannot be nil!") if value.nil?
      @serializer = value
    end

    def id_generator
      @id_generator ||= IdGenerators::IntIdGenerator.new(redis, namespace)
    end

    def id_generator=(value)
      raise(ArgumentError, "ID generator cannot be nil!") if value.nil?
      @id_generator = value
    end
  end
end
