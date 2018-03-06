require 'spec_helper'
require Rails.root.join('spec', 'models', 'shared', 'tokenable.rb')

describe TemporaryUrl do
  it_behaves_like 'tokenable'
end
