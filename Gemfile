# frozen_string_literal: true

source 'https://rubygems.org'
gemspec

# Allow CI to test against a specific Rails series, e.g. ACTIVERECORD_VERSION=8.0
rails_series = ENV['ACTIVERECORD_VERSION']
gem 'activerecord', "~> #{rails_series}.0" if rails_series

# ActiveSupport 8.0's JSON encoder passes options json 3.x rejects (quirks_mode); 8.1 fixed this.
gem 'json', '< 3' if rails_series == '8.0'

group :development do
  # Only needed to test the optional Active Job adapter
  gem 'activejob', rails_series ? "~> #{rails_series}.0" : '>= 7.2'
  gem 'rspec', '~> 3.13'
  gem 'sqlite3', '>= 2.10.2'
end

# Only needed for bin/cuetip-test. Install with: bundle config set --local with mysql
group :mysql, optional: true do
  gem 'mysql2', '~> 0.5'
end
