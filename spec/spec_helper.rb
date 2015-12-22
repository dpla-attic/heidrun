require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

ENV["RAILS_ENV"] ||= 'test'

require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

require 'factory_girl_rails'
require 'dpla/map/factories'
require 'audumbla/spec/enrichment'
require 'rdf/marmotta'
require 'webmock/rspec'

WebMock.allow_net_connect!

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.color = true
  config.formatter = :progress
  config.mock_with :rspec

  config.include FactoryGirl::Syntax::Methods

  config.use_transactional_fixtures = false
  config.infer_base_class_for_anonymous_controllers = false
  config.order = 'random'

  def clear_repository
    RDF::Marmotta.new(Krikri::Settings['marmotta']['base']).clear!
  end

  config.before(:suite) do
    clear_repository
  end

  config.after(:suite) do
    clear_repository
  end

  config.before(:each) do |example|
    if example.metadata[:webmock]
      WebMock.disable_net_connect!
    else
      WebMock.allow_net_connect!
    end
  end
end
