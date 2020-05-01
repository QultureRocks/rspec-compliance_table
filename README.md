# Rspec::ComplianceTable


Add a table DSL to your RSpec test suite. Useful for testing complex policy/permission mechanisms.

# Installation

```
# Gemfile

gem 'rspec-compliance_table'
``` 

Then run `bundle install`

# Usage

Your policy/permission class:

```
class PostPermissions
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
```

Your compliance table spec:

```
describe PostPermissions do
  let(:post) { create(:post) }
  let(:user) { create(:user) }
  
  let(:user_active) { user.tap { user.update!(active: true) } }
  let(:user_is_active_aadmin) { user.tap { user.update!(active: true, admin: true) } }
  let(:user_is_active_post_owner) { user.tap { post.update!(owner: user; user.udpate!(active: true) } }
  
  before do
    sign_in(user)
  end
  
  compliance_for :post, '
     +----------+---------+----------+----------+
     | create?  | update? | destroy? | scenario |
     +----------+---------+----------+----------+
     | y        | n       | n        | user_active
     | y        | n       | y        | user_is_active_admin
     | y        | y       | y        | user_is_active_post_owner
   '
end
```

After running the specs, if everything passes:

![passing](https://github.com/QultureRocks/rspec-compliance_table/blob/master/assets/rc1.png?raw=true)

And if anything for some reason is not compliant:

![breaking](https://github.com/QultureRocks/rspec-compliance_table/blob/master/assets/rc2.png?raw=true)
