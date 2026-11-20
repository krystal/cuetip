# frozen_string_literal: true

source 'https://rubygems.org'
gemspec

# Allow CI to test against a specific ActiveRecord series, e.g. ACTIVERECORD_VERSION=8.0
gem 'activerecord', "~> #{ENV['ACTIVERECORD_VERSION']}.0" if ENV['ACTIVERECORD_VERSION']

# ActiveSupport 8.0's JSON encoder passes options json 3.x rejects (quirks_mode); 8.1 fixed this.
gem 'json', '< 3' if ENV['ACTIVERECORD_VERSION'] == '8.0'

group :development do
  gem 'rspec', '~> 3.13'
  gem 'sqlite3', '>= 2.10.2'
end

# Only needed for bin/cuetip-test. Install with: bundle config set --local with mysql
group :mysql, optional: true do
  gem 'mysql2', '~> 0.5'
end
