# frozen_string_literal: true
# rubocop:disable all
RSpec.describe RSpec::ComplianceTable do
  class PostPermissions
    def initialize(_, _); end

    def create?
      user_active?
    end

    def update?
      user_active? && user_is_post_owner?
    end

    def destroy?
      user_active? && (user_is_post_owner? || user_is_admin?)
    end
  end

  describe PostPermissions do
    let(:user_active) { double(:user_active, reload: nil, create?: true, update?: false, destroy?: false) }
    let(:user_is_active_admin) { double(:user_active_admin, reload: nil, create?: true, update?: false, destroy?: true) }
    let(:user_is_active_post_owner) { double(:user_active_post_owner, reload: nil, create?: true, update?: true, destroy?: true) }

    before do
      allow(PostPermissions).to receive(:new).with(user_active, post).and_return(user_active)
      allow(PostPermissions).to receive(:new).with(user_is_active_admin, post).and_return(user_is_active_admin)
      allow(PostPermissions).to receive(:new).with(user_is_active_post_owner, post).and_return(user_is_active_post_owner)
    end

    def post
      @post ||= double(reload: nil)
    end

    compliance_for :post, '
      ----------+--------+------------+-----------
      | create?  | update? | destroy? | scenario |
      ----------+--------+------------+-----------
      | y        |  n      |  y       | user_active
      | y        |  n      |  y       | user_is_active_admin
      | y        |  y      |  y       | user_is_active_post_owner
    '

    context 'with match_actions_from whitelist configuration' do
      PostPermissions::ACTIONS = [:create?, :update?]

      RSpec::ComplianceTable.configure do |config|
        config.whitelist match_actions_from: 'ACTIONS'
      end

      compliance_for :post, '
        +---------+---------+----------+
        | create? | update? | scenario |
        +---------+---------+----------+
        | y       | n       | user_active
        | y       | n       | user_is_active_admin
        | y       | y       | user_is_active_post_owner
      '
    end
  end
end
# rubocop:enable all
