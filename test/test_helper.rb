ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...

  # Helper to set current tenant for multi-tenancy tests
  def with_tenant(tenant)
    ActsAsTenant.with_tenant(tenant) do
      yield
    end
  end

  # Helper to create a user with a specific tenant
  def create_user_with_tenant(tenant, attributes = {})
    default_attributes = {
      email: "user#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123",
      tenant: tenant
    }
    User.create!(default_attributes.merge(attributes))
  end
end

# Include Devise test helpers for controller and integration tests
class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
