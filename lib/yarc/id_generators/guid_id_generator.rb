require 'securerandom'

module Yarc
  module IdGenerators
    class GuidIdGenerator
      def get_unique_id
        SecureRandom.uuid
      end
    end
  end
end
