require 'spec_helper'
require 'krikri/spec/harvester'

describe LocHarvester, webmock: true do
  # before do
  #   stub_request(:get, 'http://example.com/1')
  #     .to_return(:status => 200, :body => batch_response, :headers => {})

  #   # stub_request(:get, 'http://example.com/1')
  #   #   .to_return(:status => 200, :body => batch_response_2, :headers => {})
  # end

  # subject { described_class.new(uri: '', api: { uris: request_uris }) }

  # let(:request_uris)   { ['http://example.com/1', 'http://example.com/2'] }

  # let(:batch_response) do
  #   '{"results": [{"item_id"=>"1/"}, {{"item_id"=>"2/"}], ' \
  #   '"pagination": {"of": 10, "next": "http://example.com/1.1"}}'
  # end

  # let(:batch_response_2) do
  #   '{"results": [{"item_id"=>"3/"}, {"item_id"=>"4/"}], '\
  #   '"pagination": {"of": 10}}'
  # end

  # it_behaves_like 'a harvester'
  
  describe 'initializing' do
    it 'defaults name to "loc"' do 
      expect(subject.name).to eq 'loc'
    end

    context 'with a single uri' do
      let(:request_uris) { 'http://example.com/1' }

      it 'wraps in array' do
        expect(subject.opts[:uris]).to contain_exactly(request_uris)
      end
    end
  end
end
