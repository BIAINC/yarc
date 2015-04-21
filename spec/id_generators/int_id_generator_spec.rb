require "spec_helper"
require "yarc/id_generators/int_id_generator"

describe Yarc::IdGenerators::IntIdGenerator do
  let(:redis) {mock_redis}
  let(:namespace) {%w(ns1 ns2).sample}
  let(:generator) {Yarc::IdGenerators::IntIdGenerator.new(redis, namespace)}
  let(:redis_id) {[1,2,3].sample}
  let(:redis_key) {"#{namespace}:last_id"}

  def mock_redis
    double("redis").tap do |redis|
      allow(redis).to receive(:incr).and_return(redis_id)
    end
  end

  describe "#get_unique_id" do
    it "calls redis" do
      expect(redis).to receive(:incr).once.with(redis_key).and_return(redis_id)
      generator.get_unique_id
    end

    it "returns redis id" do
      expect(generator.get_unique_id).to eq redis_id
    end
  end
end
