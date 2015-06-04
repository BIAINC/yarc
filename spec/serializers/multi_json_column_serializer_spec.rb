require "spec_helper"

describe Yarc::Serializers::MultiJsonColumnSerializer do
  let(:serializer) {subject}


  it {is_expected.to respond_to(:serialize)}
  it {is_expected.to respond_to(:deserialize)}

  describe "#key_type" do
    it "is symbol by default" do
      expect(serializer.key_type).to eq :symbol
    end

    it "can be set to symbol" do
      serializer.key_type = :symbol
      expect(serializer.key_type).to eq :symbol
    end

    it "can be set to string" do
      serializer.key_type = :string
      expect(serializer.key_type).to eq :string
    end

    it "raises on assigning an invalid value" do
      expect{serializer.key_type = :int}.to raise_error(ArgumentError)
    end
  end

  describe "#load_options" do
    it "is empty by default" do
      expect(serializer.load_options).to eq ({})
    end

    it "keeps the assigned value" do
      expected = {symbolize_keys: true}
      serializer.load_options = expected
      expect(serializer.load_options).to eq expected
    end
  end

  describe "#serialize" do
    it "serializes all columns" do
      hash = {key1: 123, key2: "123", key3: [1,2]}
      expect(serializer.serialize(hash)).to eq ["key1", "{\"value\":123}", "key2", "{\"value\":\"123\"}", "key3", "{\"value\":[1,2]}"]
    end
  end

  describe "#deserialize" do
    let(:input) {{"key1" => "{\"value\":123}", "key2" => "{\"value\":\"123\"}", "key3" => "{\"value\":[1,2]}"}}

    it "deserializes all columns" do
      expect(serializer.deserialize(input)).to eq ({key1: 123, key2: "123", key3: [1,2]})
    end

    context "when requesting symbol keys" do
      before(:each) do
        serializer.key_type = :symbol
      end

      it "returns keys as symbols" do
        expect(serializer.deserialize(input)).to eq ({key1: 123, key2: "123", key3: [1,2]})
      end
    end

    context "when requesting string keys" do
      before(:each) do
        serializer.key_type = :string
      end

      it "returns keys as strings" do
        expect(serializer.deserialize(input)).to eq ({"key1" => 123, "key2" => "123", "key3" => [1,2]})
      end
    end
  end
end
