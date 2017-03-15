class MediaResource < ActiveRecord::Base

  include Concerns::MediaResourceScope

  def self.unified_scope(scope1, scope2, scope3)
    shared_unified_scope(scope1, scope2, scope3)
  end
end
