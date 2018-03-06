class TemporaryUrl < ActiveRecord::Base
  include Concerns::Tokenable

  belongs_to :resource, polymorphic: true
end
