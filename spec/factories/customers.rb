FactoryBot.define do
  factory :customer do
    tenant
    sequence(:name) { |n| "Customer #{n}" }
    customer_type { 'particular' }
    sequence(:tax_id) { |n| "#{1000000000 + n}" }
    sequence(:phone) { |n| "9#{10000000 + n}" }
    sequence(:whatsapp) { |n| "9#{20000000 + n}" }
    sequence(:email) { |n| "customer#{n}@example.com" }
    address { Faker::Address.full_address }
    notes { Faker::Lorem.paragraph }

    trait :company do
      customer_type { 'empresa' }
      name { Faker::Company.name }
    end

    trait :school do
      customer_type { 'escola' }
      name { "#{Faker::Educator.university} School" }
    end

    trait :government do
      customer_type { 'governo' }
      name { "#{Faker::Address.city} Government" }
    end

    trait :ngo do
      customer_type { 'ong' }
      name { "#{Faker::Company.name} NGO" }
    end

    trait :reseller do
      customer_type { 'revendedor' }
    end

    trait :partner do
      customer_type { 'parceiro' }
    end

    trait :minimal do
      whatsapp { nil }
      address { nil }
      notes { nil }
    end
  end
end
