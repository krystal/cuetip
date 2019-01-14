$:.unshift(File.expand_path('../../lib', __FILE__))

require 'active_record'
ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

# Load up the migrations
ActiveRecord::Migrator.migrate(File.expand_path('../../db/migrate', __FILE__))

require 'cuetip'

# Disable logging to STDOUT
Cuetip.logger.level = Logger::UNKNOWN