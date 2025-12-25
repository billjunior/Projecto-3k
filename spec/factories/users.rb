FactoryBot.define do
  factory :user do
    tenant
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:name) { |n| "User #{n}" }
    password { 'password123' }
    password_confirmation { 'password123' }
    role { 1 } # commercial role
    department { nil }
    active { true }
    admin { false }
    super_admin { false }
    confirmed_at { Time.current }

    trait :admin do
      admin { true }
      role { 2 } # manager or higher role
    end

    trait :super_admin do
      super_admin { true }
      admin { true }
    end

    trait :commercial do
      role { 1 }
      department { 1 } # commercial_dept
    end

    trait :technical do
      role { 2 } # cyber_tech
      department { 2 } # technical_dept
    end

    trait :attendant do
      role { 3 } # attendant
    end

    trait :financial do
      department { 0 } # financial
    end

    trait :inactive do
      active { false }
    end
  end
end
