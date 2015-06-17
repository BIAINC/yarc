require "yarc/temporary_storage"
require "yarc/permanent_storage"

module Yarc
  class Cache
    def self.default
      @default ||= new(Config.new("Yarc"))
    end

    def self.default=(value)
      @default = value
    end

    attr_reader(:config)

    def initialize(config)
      raise(ArgumentError, "Config cannot be nil!") if config.nil?
      @config = config
    end

    def temporary
      @temporary ||= TemporaryStorage.new(config)
    end

    def permanent
      @permanent ||= PermanentStorage.new(config)
    end

    def in_transaction(&block)
      @config.redis.multi(&block)
    end

    def to_temporary(key)
      temporary.delete(key)
      redis_key = permanent.release(key)
      temporary.migrate(redis_key, key)
    end
  end
end
