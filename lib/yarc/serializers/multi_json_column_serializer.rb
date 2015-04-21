require "multi_json"

module Yarc
  module Serializers
    class MultiJsonColumnSerializer
      def key_type
        @key_type || :symbol
      end

      def key_type=(value)
        raise(ArgumentError, "Invalid key type!") unless [:symbol,:string].include?(value)
        @key_type = value
      end

      def load_options
        @load_options || {}
      end

      def load_options=(value)
        raise(ArgumentError, "Load options cannot be nil!") if value.nil?
        @load_options = value
      end

      def serialize(hash)
        hash.map{|k,v| [serialize_key(k), serialize_value(v)]}.flatten
      end

      def deserialize(hash)
        columns = hash.map{|k,v| [deserialize_key(k), deserialize_value(v)]}
        Hash[columns]
      end

      private

      def serialize_key(key)
        key.to_s
      end

      def serialize_value(value)
        MultiJson.dump(value: value)
      end

      def deserialize_key(key)
        key_type == :symbol ? key.to_sym : key
      end

      def deserialize_value(value)
        MultiJson.load(value, load_options).values.first
      end
    end
  end
end
