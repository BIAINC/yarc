require "spec_helper"

describe Yarc::Config do
  describe ".new" do
    it "rejects nil namespace" do
      expect{Yarc::Config.new(nil)}.to raise_error(ArgumentError)
    end

    it "rejects empty namespace" do
      expect{Yarc::Config.new("")}.to raise_error(ArgumentError)
    end

    it "accepts correct namespace" do
      expect{Yarc::Config.new("whatever")}.not_to raise_error
    end
  end

  describe "#redis" do
    let(:namespace) {SecureRandom.uuid}
    let(:config) {Yarc::Config.new(namespace)}
    let(:redis) {double("redis")}

    it "rejects nil value" do
      expect{config.redis = nil}.to raise_error(ArgumentError)
    end

    it "accepts correct value" do
      expect{config.redis = redis}.not_to raise_error
    end

    context "by default" do
      before(:each) do
        allow(Redis).to receive(:new).and_return(redis)
      end

      it "instantiates Redis" do
        expect(Redis).to receive(:new).once.and_return(redis)
        config.redis
      end

      it "returns Redis instance" do
        expect(config.redis).to eq redis
      end
    end

    it "saves the value" do
      redis = double("redis")
      config.redis = redis
      expect(config.redis).to eq(redis)
    end
  end

  describe "#temporary_item_ttl" do
    let(:namespace) {SecureRandom.uuid}
    let(:config) {Yarc::Config.new(namespace)}

    it "returns the default value" do
      expect(config.temporary_item_ttl).to eq 1800
    end

    it "rejects incorrect value" do
      expect{config.temporary_item_ttl = []}.to raise_error(ArgumentError)
    end

    it "rejects zero value" do
      expect{config.temporary_item_ttl = 0}.to raise_error(ArgumentError)
    end

    it "converts input to integer" do
      config.temporary_item_ttl = "1234"
      expect(config.temporary_item_ttl).to eq 1234
    end
  end

  describe "#serializer" do
    let(:namespace) {SecureRandom.uuid}
    let(:config) {Yarc::Config.new(namespace)}

    context "by default" do
      it "instantiates MultiJsonColumnSerializer" do
        expect(Yarc::Serializers::MultiJsonColumnSerializer).to receive(:new).once.and_call_original
        config.serializer
      end

      it "returns an instance of MultiJsonColumnSerializer" do
        serializer = double("serializer")
        allow(Yarc::Serializers::MultiJsonColumnSerializer).to receive(:new).and_return(serializer)
        expect(config.serializer).to eq serializer
      end
    end

    it "rejects nil value" do
      expect{config.serializer = nil}.to raise_error(ArgumentError)
    end

    it "returns assigned value" do
      serializer = double("serializer")
      config.serializer = serializer
      expect(config.serializer).to eq serializer
    end
  end

  describe "#id_generator" do
    let(:namespace) {%w(namespace1 namespace2).sample}
    let(:redis) {double("redis")}
    let(:config) {mock_config}

    def mock_config
      Yarc::Config.new(namespace).tap{|c| allow(c).to receive(:redis).and_return(redis)}
    end

    context "by default" do
      it "instantiates IntIdGenerator" do
        expect(Yarc::IdGenerators::IntIdGenerator).to receive(:new).once.with(redis, namespace).and_call_original
        config.id_generator
      end

      it "returns IntIdGenerator" do
        generator = Yarc::IdGenerators::IntIdGenerator.new(redis, namespace)
        allow(Yarc::IdGenerators::IntIdGenerator).to receive(:new).and_return(generator)

        expect(config.id_generator).to eq generator
      end
    end

    it "rejects nil value" do
      expect{config.id_generator = nil}.to raise_error(ArgumentError)
    end

    it "returns assigned value" do
      generator = double("generator")
      config.id_generator = generator
      expect(config.id_generator).to eq generator

    end
  end
end
