require "spec_helper"
require "yarc/redis_storage"

describe Yarc::RedisStorage do
  class Storage
    include Yarc::RedisStorage
  end

  let(:config) {Yarc::Config.new("Yarc")}
  let(:namespace) {"RedisStorage"}
  let(:storage) {Storage.new(config, namespace)}
  subject {storage}

  it {is_expected.to respond_to(:config)}
  it {is_expected.to respond_to(:namespace)}

  describe ".new" do
    it "rejects nil config" do
      expect{Storage.new(nil, namespace)}.to raise_error(ArgumentError)
    end

    it "rejects nil namespace" do
      expect{Storage.new(config, nil)}.to raise_error(ArgumentError)
    end

    it "rejects empty namespace" do
      expect{Storage.new(config, "")}.to raise_error(ArgumentError)
    end

    it "accepts correct arguments" do
      expect{Storage.new(config, namespace)}.not_to raise_error
    end

    it "assigns config" do
      expect(storage.config).to eq config
    end

    it "assigns namespace" do
      expect(storage.namespace).to eq "Yarc:RedisStorage"
    end
  end

  describe "#keys" do
    let(:keys) {["Yarc:RedisStorage:key1", "Yarc:RedisStorage:key2"]}
    let(:redis) {mock_redis}

    before(:each) do
      config.redis = redis
    end

    def mock_redis
      double("redis").tap do |r|
        allow(r).to receive(:keys).and_return(keys)
      end
    end

    it "obtains keys from redis" do
      expect(redis).to receive(:keys).once.with("Yarc:RedisStorage:*").and_return(keys)
      storage.keys
    end

    it "returns keys from redis" do
      expect(storage.keys).to eq %w(key1 key2)
    end
  end

  describe "#add" do
    let(:unique_id) {[1,2,3].sample}
    let(:generator) { double("generator", get_unique_id: unique_id)}
    let(:object)  {double("object")}

    before(:each) do
      config.id_generator = generator
      allow(storage).to receive(:set)
    end

    it "requests a unique id" do
      expect(generator).to receive(:get_unique_id).once.and_return(unique_id)
      storage.add(object)
    end

    it "saves the object with the unique id" do
      expect(storage).to receive(:set).once.with(unique_id, object)
      storage.add(object)
    end

    it "returns the unique id" do
      expect(storage.add(object)).to eq unique_id
    end
  end

  describe "#delete" do
    it "deletes keys from redis" do
      keys = %w(key1 key2)
      redis_keys = %w(Yarc:RedisStorage:key1 Yarc:RedisStorage:key2)

      expect(config.redis).to receive(:del).once.with(redis_keys)
      storage.delete(*keys)
    end
  end

  describe "#exists?" do
    let(:redis) {mock_redis}
    let(:key) {"key"}

    before(:each) do
      allow(config).to receive(:redis).and_return(redis)
    end

    def mock_redis
      double("redis").tap do |r|
        allow(r).to receive(:exists).and_return(true)
      end
    end

    it "calls redis" do
      expect(redis).to receive(:exists).once.with("Yarc:RedisStorage:#{key}").and_return(true)
      storage.exists?(key)
    end

    context "with existing key" do
      before(:each) do
        allow(redis).to receive(:exists).and_return(true)
      end

      it "returns true" do
        expect(storage.exists?(key)).to be true
      end
    end

    context "with missing key" do
      before(:each) do
        allow(redis).to receive(:exists).and_return(false)
      end

      it "returns false" do
        expect(storage.exists?(key)).to be false
      end
    end
  end

  describe "#watch" do
    let(:redis) {mock_redis}

    before(:each) do
      allow(config).to receive(:redis).and_return(redis)
    end

    def mock_redis
      double("redis").tap do |r|
        allow(r).to receive(:watch)
      end
    end

    it "watches a single key" do
      key = "test"
      expect(redis).to receive(:watch).once.with(key)
      storage.watch(key)
    end

    it "watches multiple keys" do
      keys = %w(test1 test2)
      expect(redis).to receive(:watch).once.with(*keys)
      storage.watch(*keys)
    end
  end
end
