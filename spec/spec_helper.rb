require 'rspec'
require 'rspec/autorun'
require 'simplecov'
require 'simplecov-rcov'
require 'ostruct'
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::RcovFormatter
]

SimpleCov.start do
  add_filter '/spec/'
end

require_relative '../lib/drones'

RSpec.configure do |config|
  config.before(:suite) do
    #make sure rabbit server is running when do test
    Drone.connect('amqp://127.0.0.1:5672')
  end
end


