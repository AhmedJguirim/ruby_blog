ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

# Rails 6.1 relies on concurrent-ruby loading 'logger'; versions >= 1.3.5 no longer do
require 'logger'

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.
