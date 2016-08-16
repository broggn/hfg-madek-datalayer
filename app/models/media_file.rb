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

  has_many :previews, -> { order(:created_at, :id) }, dependent: :destroy

  scope :incomplete_encoded_videos, lambda {
    where(media_type: 'video').where \
      'NOT EXISTS (SELECT NULL FROM media_files as mf ' \
                  'INNER JOIN previews ON previews.media_file_id = mf.id ' \
                  "WHERE mf.id = media_files.id AND previews.media_type = 'video')"
  }

  # The media type can be shown as an image?
  def representable_as_image?
    image? or video? or pdf?
  end

  # Can Previews be created internally?
  def previews_internal?
    image? or pdf?
  end

  # Can Previews be created using zencoder service?
  def previews_zencoder?
    content_type =~ /video|audio/
  end

  # actions

  def create_previews!(alternative_store_location = nil)
    store_location = alternative_store_location || original_store_location
    raise "Input file doesn't exist!" unless File.exist?(store_location)

    Madek::Constants::THUMBNAILS.each do |thumb_size, dimensions|
      next if thumb_size == :large && video?
      # TODO: more exception handling for the cases where
      # some thumbnails and/or previews potentially already exist ?

      store_location_new_file =
        if video?
          video_thumbnail_filename(store_location, thumb_size)
        else
          "#{thumbnail_store_location}_#{thumb_size}.jpg"
        end
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

  def delete_files
    begin
      File.delete(original_store_location)
    rescue => error # ignore errors on FILE deletion, but do log them:
      Rails.logger.warn(error)
    end
  end

  # helpers

  def pdf?
    media_type == 'document' and extension == 'pdf'
  end

  def image?
    media_type == 'image'
  end

  def video?
    media_type =~ /video/
  end

  def original_store_location
    File.join(Madek::Constants::FILE_STORAGE_DIR, guid.first, guid)
  end

  def thumbnail_store_location
    File.join(Madek::Constants::THUMBNAIL_STORAGE_DIR, guid.first, guid)
  end

  # FIXME: remove this
  def preview(size)
    previews.find_by(thumbnail: size)
  end

  private

  def video_thumbnail_filename(store_location, thumb_size)
    filename = store_location.split('/').last
    filename, extension = filename.split('.')
    variant = filename.split('_').last
    suffix = [variant, thumb_size].join('_')

    "#{thumbnail_store_location}_#{suffix}.#{extension}"
  end

end
