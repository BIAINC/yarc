require "spec_helper"
require "yarc/id_generators/guid_id_generator"

describe Yarc::IdGenerators::GuidIdGenerator do
  let(:generator) { Yarc::IdGenerators::GuidIdGenerator.new }

  describe "#get_unique_id" do
    it "generates a GUID" do
      expect(SecureRandom).to receive(:uuid).once.and_call_original
      generator.get_unique_id
    end

    it "returns a GUID" do
      guid = SecureRandom.uuid
      allow(SecureRandom).to receive(:uuid).once.and_return(guid)
      expect(generator.get_unique_id).to eq guid
    end
  end

end
