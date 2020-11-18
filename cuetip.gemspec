# frozen_string_literal: true

require File.expand_path('lib/cuetip/version', __dir__)

Gem::Specification.new do |s|
  s.name          = 'cuetip'
  s.description   = 'An ActiveRecord job queueing system'
  s.summary       = s.description
  s.homepage      = 'https://github.com/adamcooke/cuetip'
  s.licenses      = ['MIT']
  s.version       = Cuetip::VERSION
  s.files         = Dir.glob('{bin,lib,db}/**/*')
  s.executables   = ['cuetip']
  s.require_paths = ['lib']
  s.authors       = ['Adam Cooke']
  s.email         = ['me@adamcooke.io']
  s.add_runtime_dependency 'activerecord', '>= 5.0'
  s.add_runtime_dependency 'hashie'
end
