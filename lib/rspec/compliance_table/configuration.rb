# frozen_string_literal: true

require 'singleton'

# rubocop:disable all
module RSpec
  module ComplianceTable
    class Configuration
      include Singleton

      def whitelist(options = {})
        @whitelist ||= options
      end

      def actions_for(described_class)
        return described_class.instance_methods(false) if @whitelist.nil?
        return described_class.instance_methods(false) if @whitelist[:match_actions_from].nil?

        described_class.const_get(@whitelist[:match_actions_from])
      end
    end
  end
end
# rubocop:enable all
