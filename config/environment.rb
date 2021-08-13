# Load the Rails application.
require_relative 'application'

Rails.application.config.paths['db/migrate'] \
  <<  Rails.root.join('db', 'migrate_new')

# Initialize the Rails application.
Rails.application.initialize!

