FactoryBot.define do

  factory :user do |n|
    person { FactoryBot.create :person }
    email do
      Faker::Internet.email.gsub('@',
                                 '_' + SecureRandom.uuid.first(8) + '@')
    end
    login { Faker::Internet.user_name + (SecureRandom.uuid.first 8) }
    accepted_usage_terms { UsageTerms.most_recent or create(:usage_terms) }
    password { Faker::Internet.password }

    trait :deactivated do
      active_until { Date.yesterday }
    end

    after(:create) do |user|
      user.reload # to reflect the active_until db default; wtf
    end
  end

  factory :admin_user, class: User do |n|
    person { FactoryBot.create :person }
    email do
      Faker::Internet.email.gsub('@',
                                 '_' + SecureRandom.uuid.first(8) + '@')
    end
    login { Faker::Internet.user_name + (SecureRandom.uuid.first 8) }
    accepted_usage_terms { UsageTerms.most_recent or create(:usage_terms) }
    password { Faker::Internet.password }
    admin { FactoryBot.create :admin }
  end

end
