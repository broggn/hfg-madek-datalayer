FactoryGirl.define do

  factory :temporary_url do
    user { create(:user) }
    resource { create(:media_entry_with_title) }
    description { Faker::Hacker::phrases.sample }
  end

end
