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
    WebMock.allow_net_connect!
  end

  config.before(:each) do |example|
    if example.metadata[:webmock]
      WebMock.disable_net_connect!(:allow_localhost => true, 
                                   allow: 'codeclimate.com')

      # `OriginalRecord.build` will look for an existing record.  Just assume
      # there isn't one by default.
      stub_request(:head, %r{/ldp/original_record/[0-9a-f]+\z})
        .to_return(status: 404)
    else
      WebMock.allow_net_connect!
    end
  end

  # Allow connections between tests to ensure that repository clearing requests
  # still run.
  config.after(:each) do |_|
    WebMock.allow_net_connect!
  end
end
