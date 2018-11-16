class TemporaryUrl < ActiveRecord::Base
  belongs_to :resource, polymorphic: true
  belongs_to :user

  before_save do
    self.token ||= Base32::Crockford.encode(
      SecureRandom.random_number(2**160)) unless persisted?
  end

  class << self
    def find_by_token(token_param)
      tmp_url = find_by(token: token_param, revoked: false)
      return nil unless tmp_url
      if tmp_url.expires_at.nil?
        tmp_url
      else
        tmp_url.expires_at > Time.current ? tmp_url : nil
      end
    end
  end
end
