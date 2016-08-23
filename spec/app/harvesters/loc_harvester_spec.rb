require 'spec_helper'
require 'krikri/spec/harvester'

describe LocHarvester, webmock: true do
  before do
    stub_request(:get, 'http://example.com/1')
      .to_return(body: batch_response)
    stub_request(:get, 'http://example.com/1.1')
      .to_return(body: batch_response_2)
    stub_request(:get, 'http://example.com/2')
      .to_return(body: batch_response_3)

    # stub_request(:get, /.*www\.loc\.gov\/item\/.*\?fo=json/)
    #   .to_return(*records.map { |record| { body: record } })

    records.each_with_index do |record, i|
      stub_request(:get, "http://www.loc.gov/item/#{(i + 1).to_s}/?fo=json")
        .to_return(body: record)
      stub_request(:get, "https://www.loc.gov/item/#{(i + 1).to_s}/?fo=json")
        .to_return(body: record)
    end
  end

  subject { described_class.new(api: { uris: request_uris }) }

  let(:request_uris) { ['http://example.com/1', 'http://example.com/2'] }

  let(:batch_response) do
    '{"results": [{"id": "http://www.loc.gov/item/1/"}, ' \
    '{"aka": ["http://hdl.loc.gov/loc.gmd/g3300m.gar00002", ' \
    '         "http://www.loc.gov/item/2/"]}], ' \
    '"pagination": {"of": 10, "next": "http://example.com/1.1"}}'
  end

  let(:batch_response_2) do
    '{"results": [{"id": "http://www.loc.gov/item/3/"}, ' \
    '{"url": "http://www.loc.gov/item/4/"}], '\
    '"pagination": {"of": 10}}'
  end

  let(:batch_response_3) do
    '{"results": [{"id": "http://www.loc.gov/item/5/"}], ' \
    '"pagination": {"of": 10}}'
  end

  let(:records) do
    (1..5).map do |i|
      "{\"item\": {\"library_of_congress_control_number\": \"n#{i}\"}}"
    end
  end

  it_behaves_like 'a harvester' do
    # prevents 409/428 errors specific to response setup
    before { clear_repository }
  end
  
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

  describe '#records' do
    it 'contains 5 records' do
      recs = []
      5.times { recs << an_instance_of(Krikri::OriginalRecord) }

      expect(subject.records).to contain_exactly(*recs)
    end
  end
end
