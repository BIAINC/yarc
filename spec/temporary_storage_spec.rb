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
  it {is_expected.to respond_to(:exists?)}

  def create_config
    Yarc::Config.new("Yarc").tap do |config|
      config.redis = redis
      config.temporary_item_ttl = item_ttl
    end
  end

  def mock_redis
    double("redis").tap do |redis|
      allow(redis).to receive(:multi).and_yield.and_return("OK")
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
      expect(redis).to receive(:hmset).ordered.with(redis_key, *serialized_object)
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

  describe "#extend_ttl" do
    let(:key) {%w(key1 key2).sample}
    let(:redis_key) {"#{config.namespace}:Temporary:#{key}"}

    it "extends lifetime of a key" do
      expect(redis).to receive(:expire).once.with(redis_key, item_ttl)
      storage.extend_ttl(key)
    end
  end

  describe "#release" do
    let(:key) {"temporary_key"}
    let(:redis_key) {"#{config.namespace}:Temporary:#{key}"}

    before(:each) do
      allow(redis).to receive(:persist).and_return(1)
    end

    it "persists the key" do
      expect(redis).to receive(:persist).once.with(redis_key)
      storage.release(key)
    end

    context "with existing key" do
      it "returns key name" do
        expect(storage.release(key)).to eq redis_key
      end
    end

    context "with missing key" do
      before(:each) do
        allow(redis).to receive(:persist).and_return(0)
      end

      it "returns nil" do
        expect(storage.release(key)).to eq nil
      end
    end
  end

  describe "#migrate" do
    let(:original_redis_key) {"some redis key"}
    let(:new_key) {"new_key"}
    let(:new_redis_key) {"#{config.namespace}:Temporary:#{new_key}"}

    before(:each) do
      allow(redis).to receive(:rename)
    end

    it "renames the key" do
      expect(redis).to receive(:rename).once.with(original_redis_key, new_redis_key)
      storage.migrate(original_redis_key, new_key)
    end

    it "sets TTL on the new key" do
      expect(redis).to receive(:expire).once.with(new_redis_key, item_ttl)
      storage.migrate(original_redis_key, new_key)
    end
  end
end
