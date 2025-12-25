FactoryBot.define do
  factory :tenant do
    sequence(:name) { |n| "Tenant #{n}" }
    sequence(:subdomain) { |n| "tenant#{n}" }
    status { 0 } # active
    subscription_status { 'active' }
    subscription_start { Date.today }
    subscription_end { 1.year.from_now }
    subscription_expires_at { 1.year.from_now }
    subscription_plan { 'monthly' }
    last_payment_date { Date.today }
    grace_period_days { 7 }
    is_master { false }
    settings { {} }

    trait :trial do
      subscription_status { 'trial' }
      subscription_end { 30.days.from_now }
      subscription_expires_at { 30.days.from_now }
    end

    trait :expired do
      subscription_status { 'expired' }
      subscription_end { 1.day.ago }
      subscription_expires_at { 1.day.ago }
    end

    trait :grace_period do
      subscription_status { 'grace_period' }
      subscription_end { 1.day.ago }
      subscription_expires_at { 7.days.from_now }
    end

    trait :master do
      is_master { true }
      subdomain { 'master' }
    end
  end
end
