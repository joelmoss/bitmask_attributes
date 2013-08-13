# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "bitmask_attributes/version"

Gem::Specification.new do |gem|
  gem.name          = "bitmask_attributes"
  gem.summary       = %Q{Simple bitmask attribute support for ActiveRecord}
  gem.email         = "joel@developwithstyle.com"
  gem.homepage      = "http://github.com/joelmoss/bitmask_attributes"
  gem.authors       = ['Joel Moss']

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.require_paths = ['lib']
  gem.version       = BitmaskAttributes::VERSION.dup

  gem.add_dependency 'activerecord', '>= 3.1'
  gem.add_development_dependency "appraisal",     "~> 0.5.1"
end
