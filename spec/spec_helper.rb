require 'rspec'
require 'spork'
require 'bundler'
$:<< '../lib' << 'lib' << 'vendor/goliath/lib'

p Dir['vendor/goliath/lib/*']


Spork.prefork do
  Bundler.setup
  Bundler.require

  require 'goliath/test_helper'

  ::RSpec.configure do |c|
    c.include Goliath::TestHelper, :example_group => {
      :file_path => /spec\/integration/
    }
  end
end

Spork.each_run do
  # This code will be run each time you run your specs.
end




