# frozen_string_literal: true

require 'mongoid'
require 'validates_timeliness'
require 'validates_timeliness/orm/mongoid'

ValidatesTimeliness.setup do |c|
  c.extend_orms = [:mongoid]
  c.use_plugin_parser = true
  c.default_timezone = :utc
end

Time.zone = 'Australia/Melbourne'

Mongoid.configure do |config|
  config.connect_to('validates_timeliness_test')
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
