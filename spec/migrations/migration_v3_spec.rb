require 'spec_helper'
require 'spec_helper_personas'

# TODO: remove this after refactoring?

# This relies on the personas_db and runs static assertions
# after it is migrated from v2 to v3.
describe 'Migration from v2 to v3' do

  it 'User.used_keywords' do
    normin = User.find_by(login: 'normin')

    # from v2: `normin.keywords.map(&:keyword_term).map(&:term)` =>
    normins_useds_terms = ['oil', 'niger delta', 'Installation']

    expect(normin.used_keywords.map(&:term))
      .to match_array(normins_useds_terms)
  end

end
