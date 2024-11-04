require 'bundler/setup'
Bundler.setup

require 'resque-retry'
require 'resque-delay'

require 'coveralls'
require 'pry'

Coveralls.wear!
SimpleCov.minimum_coverage 100
SimpleCov.refuse_coverage_drop

RSpec::Matchers.define :have_key do |expected|
  match do |redis|
    redis.exists(expected)
  end
end
