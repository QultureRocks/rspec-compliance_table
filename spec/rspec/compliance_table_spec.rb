# frozen_string_literal: true
# rubocop:disable all
RSpec.describe RSpec::ComplianceTable do
  class UserPermissions
    def initialize(_, _); end

    %i[create show update delete].each do |method_name|
      define_method(method_name) {}
    end
  end

  describe UserPermissions do
    let(:admin) { double(:admin, reload: nil, create: true, show: true, update: true, delete: true) }
    let(:logged_in_user) { double(:admin, reload: nil, create: false, show: true, update: false, delete: false) }
    let(:logged_out_user) { double(:admin, reload: nil, create: false, show: false, update: false, delete: false) }

    before do
      allow(UserPermissions).to receive(:new).with(admin, post).and_return(admin)
      allow(UserPermissions).to receive(:new).with(logged_in_user, post).and_return(logged_in_user)
      allow(UserPermissions).to receive(:new).with(logged_out_user, post).and_return(logged_out_user)
    end

    def post
      @post ||= double(reload: nil)
    end

    compliance_for :post, '
      ----------+------+--------+--------+-----------
      | create  | show | update | delete | scenario |
      ----------+------+--------+--------+-----------
      | y       | y    |  y     |  y     | admin
      | n       | y    |  n     |  n     | logged_in_user
      | n       | n    |  n     |  n     | logged_out_user
    '

    context 'with match_actions_from whitelist configuration' do
      UserPermissions::ACTIONS = [:create, :show]

      RSpec::ComplianceTable.configure do |config|
        config.whitelist match_actions_from: 'ACTIONS'
      end

      compliance_for :post, '
        ----------+------+-----------
        | create  | show | scenario |
        ----------+------+-----------
        | y       | y    | admin
        | n       | y    | logged_in_user
        | n       | n    | logged_out_user
      '
    end
  end
end
# rubocop:enable all
