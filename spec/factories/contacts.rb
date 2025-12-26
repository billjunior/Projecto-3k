FactoryBot.define do
  factory :contact do
    association :tenant
    association :contactable, factory: :customer
    name { Faker::Name.name }
    email { Faker::Internet.email }
    phone { Faker::PhoneNumber.cell_phone }
    whatsapp { Faker::PhoneNumber.cell_phone }
    position { Faker::Job.title }
    department { Faker::Commerce.department }
    primary { false }
    notes { Faker::Lorem.paragraph }

    trait :primary do
      primary { true }
    end

    trait :for_customer do
      association :contactable, factory: :customer
    end

    trait :for_lead do
      association :contactable, factory: :lead
    end
  end
end
