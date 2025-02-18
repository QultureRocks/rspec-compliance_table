# frozen_string_literal: true

require 'pastel'
require 'terminal-table'

require 'rspec/core'
require 'rspec/expectations'
require 'rspec/compliance_table/version'
require 'rspec/compliance_table/configuration'

require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/array/access'

# rubocop:disable all
module RSpec
  module ComplianceTable
    COMPLIANCE_TOKEN = 'y'
    SCENARIO_HEADER_TOKEN = 'scenario'

    class MissingAction < StandardError; end

    def self.configure
      yield(Configuration.instance)
    end

    def compliance_for(record_name, table, options = {})
      table = prepare_table(table)

      actions = actions(table)
      scenarios = scenarios(table)
      compliance = compliance(table)

      raise_if_missing_action(actions, options)

      expected_table = {}.tap do |parsed_table|
        actions.each_with_index do |act, act_index|
          scenarios.each_with_index do |sce, sce_index|
            parsed_table[sce] ||= {}
            parsed_table[sce][act] = compliance[sce_index][act_index]
          end
        end
      end

      run_compliance_matchers(expected_table, actions, scenarios, compliance, record_name)
    end

    private

    def actions(table)
      table[1].split('|').map(&:strip).reject(&:blank?).map(&:to_sym).to(-2)
    end

    def scenarios(table)
      table.from(3).map { |line| line.split('|').map(&:strip).reject(&:blank?).last }
    end

    def compliance(table)
      table.from(3).map { |line| line.split('|').map(&:strip).reject(&:blank?).to(-2) }.map { |vs| vs.map { |vv| vv == COMPLIANCE_TOKEN } }
    end

    def prepare_table(table)
      table.split("\n").reject(&:blank?)
    end

    def raise_if_missing_action(actions, options)
      options[:ignore] ||= []

      expected_actions = (Configuration.instance.actions_for(described_class).presence).map(&:to_s)
      not_mapped_actions = (expected_actions - options[:ignore].map(&:to_s)) - (actions.map(&:to_s) & expected_actions)

      raise MissingAction, "The compliance table doesn't have every possible action for the #{described_class} class. The missing actions were: #{not_mapped_actions.join(',')}" if not_mapped_actions.any?
    end

    def run_compliance_matchers(expected_table, actions, scenarios, _boolean_values, record_name)
      actual_table = {}

      example do
        scenarios.each do |scenario|
          send(record_name).reload
          permission = described_class.new(send(scenario), send(record_name))

          actions.each do |action|
            actual_table[scenario] ||= {}
            actual_table[scenario][action] = permission.send(action)

            if actual_table[scenario][action] != expected_table[scenario][action]
              actual_table[scenario][action] = "#{expected_table[scenario][action].to_s.upcase}*"
            end
          end
        end

        def prepare_compliance_output(table, actions, scenarios)
          rows = []

          compliance_values = table.values.map(&:values)
          compliance_values.each_with_index { |cv, i| rows << cv.concat(Array(scenarios[i])) }

          ::Terminal::Table.new rows: rows, headings: actions.concat(Array(SCENARIO_HEADER_TOKEN))
        end

        expect(prepare_compliance_output(actual_table, actions, scenarios)).to be_compliant
      end
    end
  end
end

RSpec.configure do |config|
  config.extend RSpec::ComplianceTable
end

RSpec::Matchers.define :be_compliant do |_expected|
  pass = true

  match do |actual|
    actual.rows.each do |row|
      pass = row.cells.none? { |cell| cell.value.to_s =~ /\*/ }
      break unless pass
    end

    pass.tap { pass ? puts(Pastel.new.green(actual)) : puts(Pastel.new.red(actual)) }
  end

  failure_message do |_actual|
    'Non compliant, fix the ones marked with an asterisk*'
  end
end

RSpec::SharedContext.include RSpec::ComplianceTable
# rubocop:enable all
