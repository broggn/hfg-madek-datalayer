# -*- encoding : utf-8 -*-
# require 'digest'

class MediaFile < ActiveRecord::Base
  include Concerns::MediaType

  # include MediaFileModules::FileStorageManagement
  # include MediaFileModules::Previews
  # include MediaFileModules::MetaDataExtraction

  belongs_to :media_entry, foreign_key: :media_entry_id
  has_many :zencoder_jobs, dependent: :destroy
  belongs_to :uploader, class_name: 'User'

  validates_presence_of :uploader

  before_create do
    self.guid ||= UUIDTools::UUID.random_create.hexdigest
    self.access_hash ||= SecureRandom.uuid
  end

  before_create :set_media_type

  after_commit :delete_files, on: :destroy

  serialize :meta_data, Hash

  def delete_files
    begin
      File.delete(original_store_location)
    rescue Exception => error # ignore errors on FILE deletion, but do log them:
      Rails.logger.warn(error)
    end
  end

  has_many :previews, -> { order(:created_at, :id) }, dependent: :destroy

  scope :incomplete_encoded_videos, lambda {
    where(media_type: 'video').where \
      'NOT EXISTS (SELECT NULL FROM media_files as mf ' \
                  'INNER JOIN previews ON previews.media_file_id = mf.id ' \
                  "WHERE mf.id = media_files.id AND previews.media_type = 'video')"
  }

  ################################################################################

  def create_previews!(alternative_store_location = nil)
    store_location = alternative_store_location || original_store_location
    raise "Input file doesn't exist!" unless File.exist?(store_location)

    Madek::Constants::THUMBNAILS.each do |thumb_size, dimensions|
      # TODO: more exception handling for the cases where
      # some thumbnails and/or previews potentially already exist ?
      store_location_new_file = "#{thumbnail_store_location}_#{thumb_size}.jpg"
      w = dimensions.try(:fetch, :width)
      h = dimensions.try(:fetch, :height)

      FileConversion.convert(store_location,
                             store_location_new_file, w, h)

      previews.create!(content_type: 'image/jpeg',
                       filename: store_location_new_file.split('/').last,
                       height: h,
                       width: w,
                       thumbnail: thumb_size)
    end
  end

  def preview(size)
    previews.find_by(thumbnail: size)
  end

  def representable_as_image?
    ['image', 'video'].include? media_type
  end

  def needs_previews?
    image? or pdf?
  end

  def pdf?
    media_type == 'document' and extension == 'pdf'
  end

  def image?
    media_type == 'image'
  end

  def video?
    media_type =~ /video/
  end

  def audio_video?
    media_type =~ /video|audio/
  end

  def original_store_location
    File.join(Madek::Constants::FILE_STORAGE_DIR, guid.first, guid)
  end

  def thumbnail_store_location
    File.join(Madek::Constants::THUMBNAIL_STORAGE_DIR, guid.first, guid)
  end
end
