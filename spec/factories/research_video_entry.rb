FactoryGirl.define do


  factory :research_video_entry, parent: :media_entry do
  end

  factory :research_video_media_file, parent: :media_file do
    association :media_entry, factory: :research_video_entry
    before :create do
    end
  end



end
