FactoryGirl.define do


  factory :research_video_entry, parent: :media_entry do
  end

  factory :research_video_media_file, parent: :media_file do
    association :media_entry, factory: :research_video_entry
    before :create do
      Madek::System.execute_cmd! \
        "cp -r #{Madek::Constants::DATALAYER_ROOT_DIR.join(
          'spec', 'data', 'rv_files', 'originals', '*')} " \
        " #{Madek::Constants::FILE_STORAGE_DIR} "

      Madek::System.execute_cmd! \
        "cp -r #{Madek::Constants::DATALAYER_ROOT_DIR.join(
          'spec', 'data', 'rv_files', 'thumbnails', '*')} " \
        " #{Madek::Constants::THUMBNAIL_STORAGE_DIR} "
    end
  end



end
