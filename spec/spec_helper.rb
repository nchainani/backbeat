$: << File.expand_path(File.join(__FILE__, "../.."))

ENV['RACK_ENV'] = "test"

require 'bundler'

Bundler.setup
Bundler.require(:default, :test)

require 'mongoid'
mongo_path = File.expand_path(File.join(__FILE__, "..", "..", "config", "mongoid.yml"))
Mongoid.load!(mongo_path, :test)

FullRackApp = Rack::Builder.parse_file(File.expand_path(File.join(__FILE__,'..','..','config.ru'))).first

RSPEC_CONSTANT_USER_CLIENT_ID = UUID.generate

FactoryGirl.find_definitions

RSpec.configuration.before(:each) do
  Timecop.freeze(Time.now)
  #Mongoid::Sessions.default.collections.select {|c| c.name !~ /system/ }.each(&:drop)
end

RSpec.configuration.after(:each) do
  Timecop.return
  Mongoid::Sessions.default.collections.select {|c| c.name !~ /system/ }.each(&:drop)
end

RSpec.configuration.after(:suite) do
  Mongoid::Sessions.default.collections.select {|c| c.name !~ /system/ }.each(&:drop)
end

RSpec.configure do |config|
  # Use color in STDOUT
  config.color_enabled = true

  # Use the specified formatter
  config.formatter = :documentation # :progress, :html, :textmate
end