ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

require "#{Rails.root}/config/test.rb"

class ActiveSupport::TestCase
  # Add more helper methods to be used by all tests here...
end
