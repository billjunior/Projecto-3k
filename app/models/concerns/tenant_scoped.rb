module TenantScoped
  extend ActiveSupport::Concern

  included do
    acts_as_tenant :tenant
    validates :tenant, presence: true
  end
end
