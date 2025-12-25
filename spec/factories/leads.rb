FactoryBot.define do
  factory :lead do
    tenant
    sequence(:name) { |n| "Lead #{n}" }
    sequence(:email) { |n| "lead#{n}@example.com" }
    sequence(:phone) { |n| "9#{30000000 + n}" }
    company { Faker::Company.name }
    source { Faker::Marketing.buzzwords }
    classification { 1 } # warm
    contact_source { 0 } # whatsapp
    notes { Faker::Lorem.paragraph }
    assigned_to_user { nil }
    converted_to_customer { nil }
    converted_at { nil }

    trait :hot do
      classification { 2 }
    end

    trait :cold do
      classification { 0 }
    end

    trait :warm do
      classification { 1 }
    end

    trait :assigned do
      assigned_to_user { association :user, tenant: tenant }
    end

    trait :converted do
      converted_to_customer { association :customer, tenant: tenant }
      converted_at { Time.current }
    end

    trait :from_whatsapp do
      contact_source { 0 }
    end

    trait :from_phone do
      contact_source { 1 }
    end

    trait :from_instagram do
      contact_source { 2 }
    end

    trait :from_facebook do
      contact_source { 3 }
    end
  end
end
