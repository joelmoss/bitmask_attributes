require "rubygems"
require 'bundler/setup'

require 'minitest/autorun'

require 'active_record'
require 'shoulda'

$:.unshift File.expand_path("../../lib", __FILE__)
require 'bitmask_attributes'


ActiveRecord::Base.establish_connection(
  :adapter  => 'sqlite3',
  :database => ':memory:'
)


# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }
