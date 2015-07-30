require "spec_helper"

describe Yarc::PermanentStorage do
  let(:config) {Yarc::Config.new("Yarc:PermanentStorage:Test")}
  let(:storage) {Yarc::PermanentStorage.new(config)}
  let(:redis) {double("redis")}
  let(:object) {{"key" => "value"}}

  subject {storage}

  before(:each) do
    allow(Redis).to receive(:new).and_return(redis)
  end

  it {is_expected.to respond_to(:config)}
  it {is_expected.to respond_to(:namespace)}
  it {is_expected.to respond_to(:keys)}
  it {is_expected.to respond_to(:add)}
  it {is_expected.to respond_to(:delete)}
  it {is_expected.to respond_to(:exists?)}

  describe ".new" do
    it "rejects nil config" do
      expect{Yarc::PermanentStorage.new(nil)}.to raise_error(ArgumentError)
    end

    it "accepts correct config" do
      expect{Yarc::PermanentStorage.new(config)}.not_to raise_error
    end

    it "assigns the config" do
      expect(storage.config).to eq config
    end
  end

  describe "#set" do
    let(:key) {SecureRandom.uuid}

    before(:each) do
      allow(redis).to receive(:hmset)
    end

    it "serializes the value" do
      expect(config.serializer).to receive(:serialize).once.with(object).and_call_original
      storage.set(key, object)
    end

    it "sets the value" do
      serialized = config.serializer.serialize(object)
      allow(config.serializer).to receive(:serialize).and_return(serialized)
      expect(redis).to receive(:hmset).once.with("#{config.namespace}:Permanent:#{key}", *serialized)
      storage.set(key, object)
    end
  end

  describe "#get" do
    let(:key) {SecureRandom.uuid}
    let(:raw_object) {Hash[*config.serializer.serialize(object)]}

    before(:each) do
      allow(redis).to receive(:hgetall).and_return(raw_object)
    end

    it "reads from redis" do
      expect(redis).to receive(:hgetall).once.with("#{config.namespace}:Permanent:#{key}").and_return(raw_object)
      storage.get(key)
    end

    it "deserializes the value" do
      expect(config.serializer).to receive(:deserialize).once.with(raw_object).and_call_original
      storage.get(key)
    end

    it "returns deserialized value" do
      deserialized = config.serializer.deserialize(raw_object)
      allow(config.serializer).to receive(:deserialize).and_return(deserialized)
      expect(storage.get(key)).to eq deserialized
    end
  end

  describe "#release" do
    it "returns key name" do
      expect(storage.release("foo")).to eq "Yarc:PermanentStorage:Test:Permanent:foo"
    end
  end

  describe "#migrate" do
    let(:redis_key) {"some redis key"}
    let(:new_key) {"new_key"}

    it "renames the key" do
      expect(redis).to receive(:rename).once.with(redis_key, "Yarc:PermanentStorage:Test:Permanent:#{new_key}")
      storage.migrate(redis_key, new_key)
    end
  end
end
