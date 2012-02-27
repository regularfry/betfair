# require 'simplecov'
# SimpleCov.start

require 'betfair'
require 'savon_spec'

RSpec.configure do |config|
  HTTPI.log = false
  Savon.log = false
  config.include Savon::Spec::Macros
  Savon::Spec::Fixture.path = File.expand_path("../fixtures", __FILE__)
end
