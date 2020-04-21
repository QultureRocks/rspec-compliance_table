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
      | yay     | yay  |  yay   |  yay   | admin
      | nay     | yay  |  nay   |  nay   | logged_in_user
      | nay     | nay  |  nay   |  nay   | logged_out_user
    '
  end
end
# rubocop:enable all
