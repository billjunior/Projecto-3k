require 'rails_helper'

RSpec.describe Tenant, type: :model do
  describe 'validations' do
    it 'has a valid factory' do
      tenant = build(:tenant)
      expect(tenant).to be_valid
    end

    it 'requires a name' do
      tenant = build(:tenant, name: nil)
      expect(tenant).not_to be_valid
      expect(tenant.errors[:name]).to include("não pode ficar em branco")
    end

    it 'requires a unique subdomain' do
      create(:tenant, subdomain: 'test')
      duplicate_tenant = build(:tenant, subdomain: 'test')
      expect(duplicate_tenant).not_to be_valid
      expect(duplicate_tenant.errors[:subdomain]).to include('já está em uso')
    end
  end

  describe 'traits' do
    it 'creates a trial tenant' do
      tenant = create(:tenant, :trial)
      expect(tenant.subscription_status).to eq('trial')
    end

    it 'creates an expired tenant' do
      tenant = create(:tenant, :expired)
      expect(tenant.subscription_status).to eq('expired')
      expect(tenant.subscription_end).to be < Date.today
    end

    it 'creates a master tenant' do
      tenant = create(:tenant, :master)
      expect(tenant.is_master).to be true
      expect(tenant.subdomain).to eq('master')
    end
  end

  describe 'subscription status' do
    it 'identifies active subscription' do
      tenant = create(:tenant, subscription_status: 'active')
      expect(tenant.subscription_status).to eq('active')
    end

    it 'has grace period days' do
      tenant = create(:tenant)
      expect(tenant.grace_period_days).to eq(7)
    end
  end
end
