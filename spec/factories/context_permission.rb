FactoryGirl.define do
  factory :context_api_client_permission,
          class: 'Permissions::ContextApiClientPermission' do
    context
    api_client

    trait :viewable do
      view true
    end

    trait :unviewable do
      view false
    end
  end
end
