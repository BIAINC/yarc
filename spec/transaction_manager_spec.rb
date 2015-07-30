require "spec_helper"

describe Yarc::TransactionManager do
  let(:redis) {mock_redis}
  let(:tm) {Yarc::TransactionManager.new(redis)}

  def mock_redis
    double("redis").tap do |r|
      allow(r).to receive(:multi).and_yield
    end
  end

  describe "#in_transaction" do
    it "calls redis" do
      expect(redis).to receive(:multi).once.and_yield
      tm.in_transaction {}
    end

    it "yields control" do
      expect{|b| tm.in_transaction(&b)}.to yield_control.once
    end

    it "propagates exceptions" do
      expect{tm.in_transaction{raise "Test"}}.to raise_error("Test")
    end

    it "swallows Yarc::Transaction::Discard" do
      expect{tm.in_transaction{raise Yarc::Transaction::Discard}}.to_not raise_error
    end
  end
end
