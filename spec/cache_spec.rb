require "spec_helper"

describe Yarc::Cache do
  let(:namespace) {%w(test1 test2).sample}
  let(:config) {double("config", namespace: namespace)}
  let(:cache) {Yarc::Cache.new(config)}

  describe ".default" do
    before(:each) do
      Yarc::Cache.default = nil
      allow(Yarc::Config).to receive(:new).and_return(config)
    end

    it "instantiates the default config" do
      expect(Yarc::Config).to receive(:new).once.with("Yarc").and_call_original
      Yarc::Cache.default
    end

    it "instantiates the cache" do
      expect(Yarc::Cache).to receive(:new).once.with(config).and_call_original
      Yarc::Cache.default
    end

    it "returns the cache" do
      expected = Yarc::Cache.new(config)
      allow(Yarc::Cache).to receive(:new).and_return(expected)
      expect(Yarc::Cache.default).to eq expected
    end
  end

  describe ".new" do
    it "rejects nil config" do
      expect{Yarc::Cache.new(nil)}.to raise_error(ArgumentError)
    end

    it "accepts correct config" do
      expect{Yarc::Cache.new(config)}.to_not raise_error
    end

    it "saves the config" do
      expect(Yarc::Cache.new(config).config).to eq config
    end
  end

  describe "#temporary" do
    it "instantiates the storage" do
      expect(Yarc::TemporaryStorage).to receive(:new).once.with(config).and_call_original
      cache.temporary
    end

    it "returns the storage" do
      storage = Yarc::TemporaryStorage.new(config)
      allow(Yarc::TemporaryStorage).to receive(:new).and_return(storage)
      expect(cache.temporary).to eq storage
    end

    it "caches the storage" do
      expect(cache.temporary).to eq cache.temporary
    end
  end

  describe "#permanent" do
    it "instantiates the storage" do
      expect(Yarc::PermanentStorage).to receive(:new).once.with(config).and_call_original
      cache.permanent
    end

    it "returns the storage" do
      storage = Yarc::PermanentStorage.new(config)
      allow(Yarc::PermanentStorage).to receive(:new).and_return(storage)
      expect(cache.permanent).to eq storage
    end

    it "caches the storage" do
      expect(cache.permanent).to eq cache.permanent
    end
  end

  describe "#in_transaction" do
    let(:transaction_manager) {mock_transaction_manager}

    before(:each) do
      allow(config).to receive(:transaction_manager).and_return(transaction_manager)
    end

    def mock_transaction_manager
      double("transaction manager").tap do |tm|
        allow(tm).to receive(:in_transaction).and_yield
      end
    end

    it "calls the transaction manager" do
      expect(transaction_manager).to receive(:in_transaction).once.and_yield
      cache.in_transaction {}
    end

    it "yields control" do
      expect{|b| cache.in_transaction(&b)}.to yield_control.once
    end

    it "doesn't swallow exception" do
      expect{cache.in_transaction{raise "Test"}}.to raise_error("Test")
    end
  end

  describe "#unwatch" do
    before(:each) do
      allow(config).to receive(:redis).and_return(mock_redis)
    end

    def mock_redis
      double("redis").tap do |r|
        allow(r).to receive(:unwatch)
      end
    end

    it "calls redis" do
      expect(config.redis).to receive(:unwatch).once
      cache.unwatch
    end
  end
end
