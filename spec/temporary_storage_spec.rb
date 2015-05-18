require "spec_helper"

describe Yarc::TemporaryStorage do
  let(:config) {create_config}
  let(:redis) {mock_redis}
  let(:storage) {Yarc::TemporaryStorage.new(config)}
  subject {storage}
  let(:item_ttl) {[100,200].sample}

  it {is_expected.to respond_to(:config)}
  it {is_expected.to respond_to(:namespace)}
  it {is_expected.to respond_to(:keys)}
  it {is_expected.to respond_to(:add)}
  it {is_expected.to respond_to(:delete)}

  def create_config
    Yarc::Config.new("Yarc").tap do |config|
      config.redis = redis
      config.temporary_item_ttl = item_ttl
    end
  end

  def mock_redis
    double("redis").tap do |redis|
      allow(redis).to receive(:multi).and_yield
      allow(redis).to receive(:expire)
    end
  end

  describe ".new" do
    it "rejects nil config" do
      expect{Yarc::TemporaryStorage.new(nil)}.to raise_error(ArgumentError)
    end

    it "assigns the config" do
      expect(storage.config).to eq config
    end
  end

  describe "#set" do
    let(:key) {%w(key1 key2).sample}
    let(:object) {{"key" => "value"}}
    let(:serialized_object) {config.serializer.serialize(object)}
    let(:redis_key) {"#{config.namespace}:Temporary:#{key}"}

    before(:each) do
      allow(redis).to receive(:hmset)
      allow(redis).to receive(:expire)
    end

    it "serializes data" do
      expect(config.serializer).to receive(:serialize).once.with(object).and_call_original
      storage.set(key, object)
    end

    it "adds data with expiration" do
      expect(redis).to receive(:hmset).ordered.with(redis_key, serialized_object)
      expect(redis).to receive(:expire).ordered.with(redis_key, item_ttl)

      storage.set(key, object)
    end
  end

  describe "#get" do
    let(:key) {%w(key1 key2).sample}
    let(:object) {{"key" => "value"}}
    let(:serialized_object) {Hash[*config.serializer.serialize(object)]}

    before(:each) do
      allow(redis).to receive(:hgetall)
      allow(redis).to receive(:multi).and_yield.and_return([Hash[serialized_object], 1])
    end

    it "deserializes redis data" do
      expect(config.serializer).to receive(:deserialize).once.with(serialized_object).and_call_original
      storage.get(key)
    end
  end

  describe "#extend" do
    let(:key) {%w(key1 key2).sample}
    let(:redis_key) {"#{config.namespace}:Temporary:#{key}"}

    it "extends lifetime of a key" do
      expect(redis).to receive(:expire).once.with(redis_key, item_ttl)
      storage.extend(key)
    end
  end

  describe "#release" do
    let(:key) {%w(key1 key2).sample}
    let(:redis_key) {"#{config.namespace}:Temporary:#{key}"}

    before(:each) do
      allow(redis).to receive(:rename)
      allow(redis).to receive(:persist)
    end

    it "persists the key" do
      expect(redis).to receive(:persist).once.with(redis_key)
      storage.release(key)
    end

    it "returns redis key" do
      expect(storage.release(key)).to eq redis_key
    end
  end

  describe "#migrate" do
    let(:key) {%w(key1 key2).sample}
    let(:old_redis_key){%w(old1 old2).sample}
    let(:new_redis_key){"#{config.namespace}:Temporary:#{key}"}

    before(:each) do
      allow(redis).to receive(:rename)
      allow(redis).to receive(:expire)
    end

    it "renames the key" do
      expect(redis).to receive(:rename).once.with(old_redis_key, new_redis_key)
      storage.migrate(old_redis_key, key)
    end

    it "sets ttl on the key" do
      expect(redis).to receive(:expire).once.with(new_redis_key, item_ttl)
      storage.migrate(old_redis_key, key)
    end
  end
end
