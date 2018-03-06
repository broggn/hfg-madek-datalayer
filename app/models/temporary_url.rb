class TemporaryUrl < ActiveRecord::Base
  belongs_to :resource, polymorphic: true
  belongs_to :user

  before_save do
    self.token ||= Base32::Crockford.encode(
      SecureRandom.random_number(2**160)) unless persisted?
  end

  class << self
    def find_by_token(token_param)
      find_by(
        'token = ? AND revoked = ? AND expires_at > ?',
        token_param,
        false,
        Time.current
      )
    end
  end
end
