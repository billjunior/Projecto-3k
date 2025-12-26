FactoryBot.define do
  factory :communication do
    association :tenant
    association :communicable, factory: :customer
    association :created_by_user, factory: :user
    communication_type { :note }
    subject { Faker::Lorem.sentence }
    content { Faker::Lorem.paragraph(sentence_count: 3) }
    completed_at { nil }

    trait :email do
      communication_type { :email }
      subject { Faker::Lorem.sentence }
    end

    trait :call do
      communication_type { :call }
      subject { "Chamada telefónica" }
    end

    trait :meeting do
      communication_type { :meeting }
      subject { Faker::Lorem.sentence }
    end

    trait :whatsapp do
      communication_type { :whatsapp }
      subject { "Mensagem WhatsApp" }
    end

    trait :completed do
      completed_at { Faker::Time.backward(days: 7) }
    end

    trait :for_customer do
      association :communicable, factory: :customer
    end

    trait :for_lead do
      association :communicable, factory: :lead
    end

    trait :for_opportunity do
      association :communicable, factory: :opportunity
    end

    trait :for_contact do
      association :communicable, factory: :contact
    end
  end
end
