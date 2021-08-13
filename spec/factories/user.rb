FactoryGirl.define do

  factory :user do
    person { FactoryGirl.create :person }
    email do
      Faker::Internet.email.gsub('@',
                                 '_' + SecureRandom.uuid.first(8) + '@')
    end
    login { Faker::Internet.user_name + (SecureRandom.uuid.first 8) }
    accepted_usage_terms { UsageTerms.most_recent or create(:usage_terms) }
    password { SecureRandom.uuid }
    is_deactivated false

    factory :admin_user do
      admin
    end
  end

end
