module MultiTenancyHelpers
  # Helper to set current tenant for multi-tenancy tests
  def set_tenant(tenant)
    ActsAsTenant.current_tenant = tenant
  end

  # Helper to run a block with a specific tenant
  def with_tenant(tenant, &block)
    ActsAsTenant.with_tenant(tenant, &block)
  end

  # Helper to create a tenant with default attributes
  def create_test_tenant(attributes = {})
    create(:tenant, attributes)
  end
end

RSpec.configure do |config|
  config.include MultiTenancyHelpers

  # Ensure tenant is cleared between tests
  config.before(:each) do
    ActsAsTenant.current_tenant = nil
  end

  # For request specs, set a default tenant
  config.before(:each, type: :request) do
    @tenant = create(:tenant) unless defined?(@tenant)
    ActsAsTenant.current_tenant = @tenant
  end

  # For controller specs, set a default tenant
  config.before(:each, type: :controller) do
    @tenant = create(:tenant) unless defined?(@tenant)
    ActsAsTenant.current_tenant = @tenant
  end
end
