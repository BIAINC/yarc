require "yarc/temporary_storage"
require "yarc/permanent_storage"
require "yarc/transaction"

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

    def make_temporary(key, must_exist)
      permanent.send_to(key, temporary, must_exist)
    end

    def make_permanent(key, must_exist)
      temporary.send_to(key, permanent, must_exist)
    end

    def in_transaction(&block)
      @config.transaction_manager.in_transaction(&block)
    end

    def unwatch
      config.redis.unwatch
    end
  end
end
