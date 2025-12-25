FactoryBot.define do
  factory :opportunity do
    tenant
    customer { association :customer, tenant: tenant }
    lead { nil }
    sequence(:title) { |n| "Opportunity #{n}" }
    description { Faker::Lorem.paragraph }
    value { Faker::Number.decimal(l_digits: 4, r_digits: 2) }
    probability { 50 }
    stage { 0 } # new
    contact_source { 0 } # whatsapp
    expected_close_date { 30.days.from_now }
    actual_close_date { nil }
    won_lost_reason { nil }
    assigned_to_user { association :user, tenant: tenant }
    created_by_user { association :user, tenant: tenant }

    trait :new do
      stage { 0 }
      probability { 10 }
    end

    trait :qualified do
      stage { 1 }
      probability { 25 }
    end

    trait :proposal do
      stage { 2 }
      probability { 50 }
    end

    trait :negotiation do
      stage { 3 }
      probability { 75 }
    end

    trait :won do
      stage { 4 }
      probability { 100 }
      actual_close_date { Date.today }
      won_lost_reason { 'Cliente aceitou a proposta' }
    end

    trait :lost do
      stage { 5 }
      probability { 0 }
      actual_close_date { Date.today }
      won_lost_reason { 'Preço alto' }
    end

    trait :from_lead do
      lead { association :lead, tenant: tenant }
    end

    trait :high_value do
      value { Faker::Number.decimal(l_digits: 6, r_digits: 2) }
      probability { 75 }
    end

    trait :low_value do
      value { Faker::Number.decimal(l_digits: 3, r_digits: 2) }
      probability { 25 }
    end
  end
end
