require 'spec_helper'
require 'webmock/rspec'

describe IaHarvester, :webmock => true do

  let(:base_search_url) { 'http://archive.org/advancedsearch.php?output=json' }
  let(:collection_qs) { '&q=collection:(foo)' }
  let(:search_page_1_url) { base_search_url + collection_qs + '&page=1&rows=2' }
  let(:search_page_2_url) { base_search_url + collection_qs + '&page=2&rows=2' }
  let(:base_download_url) { 'http://archive.org/download' }
  let(:base_redirect_url) { 'http://redirect.archive.org' }
  let(:id1_meta_url) { base_download_url + '/id1/id1_meta.xml' }
  let(:id2_meta_url) { base_download_url + '/id2/id2_meta.xml' }
  let(:id3_meta_url) { base_download_url + '/id3/id3_meta.xml' }
  let(:id4_meta_url) { base_download_url + '/id4/id4_meta.xml' }

  let(:search_page_1_response) do
    <<-EOS
{
    "responseHeader": {
        "status": 0,
        "QTime": 6,
        "params": {
            "q": "collection:\\"foo\\"",
            "qin": "collection:\\"foo\\"",
            "fl": "identifier",
            "wt": "json",
            "rows": "2",
            "start": 0
        }
    },
    "response": {
        "docs": [
            {
                "identifier": "id1"
            },
            {
                "identifier": "id2"
            }
        ],
        "numFound": 4,
        "start": 0
    }
}
    EOS
  end

  let(:search_page_2_response) do
    <<-EOS
{
    "responseHeader": {
        "status": 0,
        "QTime": 6,
        "params": {
            "q": "collection:\\"foo\\"",
            "qin": "collection:\\"foo\\"",
            "fl": "identifier",
            "wt": "json",
            "rows": "2",
            "start": 2
        }
    },
    "response": {
        "docs": [
            {
                "identifier": "id3"
            },
            {
                "identifier": "id4"
            }
        ],
        "numFound": 4,
        "start": 0
    }
}
    EOS
  end

  def meta_response(id)
    <<-EOS
<?xml version="1.0" encoding="UTF-8"?>
<metadata>
  <title>A Title for #{id}</title>
  <creator>The Creator of #{id}</creator>
  <publisher>The Publisher of #{id}</publisher>
  <date>1923</date>
  <language>eng</language>
  <!-- other stuff -->
  <collection>foo</collection>
</metadata>
    EOS
  end

  let(:marc_response) do
    <<-EOS
<?xml version="1.0" encoding="UTF-8"?>
<record xmlns="http://www.loc.gov/MARC21/slim">
  <leader>00590cam a2200193I  4500</leader>
  <controlfield tag="001">1384748</controlfield>
  <controlfield tag="005">20020511025700.0</controlfield>
  <controlfield tag="008">961017s1923    mau           000 1 eng  </controlfield>
  <datafield tag="010" ind1=" " ind2=" ">
    <subfield code="a">123456789</subfield>
  </datafield>
  <!-- lots of other datafields -->
</record>
    EOS
  end

  subject do
    opts = { uri: base_search_url,
             ia: { collections: ['foo'], threads: 2 } }
    IaHarvester.new(opts)
  end

  before(:each) do
    stub_request(:get, search_page_1_url)
      .to_return(status: 200, body: search_page_1_response, headers: {})
    stub_request(:get, search_page_2_url)
      .to_return(status: 200, body: search_page_2_response, headers: {})

    %w(id1 id2 id3 id4).each do |id|
      stub_request(:get, "#{base_download_url}/#{id}/#{id}_files.xml")
        .to_return(status: 200,
                   body: '<files>files</files>',
                   headers: {})
    end

    %w(id1 id2 id3 id4).each do |id|
      stub_request(:get, "#{base_download_url}/#{id}/#{id}_meta.xml")
        .to_return(status: 302, body: '', headers: {'Location' => "#{base_redirect_url}/#{id}_meta.xml"})
      stub_request(:get, "#{base_redirect_url}/#{id}_meta.xml")
        .to_return(status: 200, body: meta_response(id), headers: {})
    end

    %w(id1 id2 id3).each do |id|
      stub_request(:get, "#{base_download_url}/#{id}/#{id}_marc.xml")
        .to_return(status: 302, body: '', headers: {'Location' => "#{base_redirect_url}/#{id}_marc.xml"})
      stub_request(:get, "#{base_redirect_url}/#{id}_marc.xml")
        .to_return(status: 200, body: marc_response, headers: {})
    end

    # some records don't have any marc :( ... but that's ok
    stub_request(:get, "#{base_download_url}/id4/id4_marc.xml")
      .to_return(status: 302, body: '', headers: {'Location' => "#{base_redirect_url}/id4_marc.xml"})
    stub_request(:get, "#{base_redirect_url}/id4_marc.xml")
      .to_return(status: 404, body: 'Not Found', headers: {})
  end

  describe '#count' do
    it 'counts records' do
      expect(subject.count).to eq(4)
    end
  end

  describe '#records' do
    let(:doc) { Nokogiri::XML(subject.records.first.content) }

    it 'fetches a record' do
      expect(doc.xpath('//metadata/title')[0].text)
        .to eq('A Title for id1')
    end

    it 'includes marc data when available' do
      expect(doc.xpath('//metadata/marc/record/datafield/subfield')[0].text)
        .to eq('123456789')
    end

    it 'includes file data when available' do
      expect(doc.xpath('//metadata/files')[0].text).to eq('files')
    end

    it 'fetches all documents' do
      expect(subject.records.count).to eq(4)
    end

    it 'pages correctly' do
      id = 1
      subject.records.each do |r|
        parsed = Nokogiri::XML(r.content)
        expect(parsed.xpath('//metadata/title')[0].text)
          .to eq("A Title for id#{id}")
        id += 1
      end
    end

    it 'keeps going after hitting a bad record' do
      stub_request(:get, "#{base_download_url}/id1/id1_meta.xml")
        .to_return(status: 500, body: 'disaster strikes!', headers: {})

      expect(subject.records.count).to eq(3)
    end

    describe 'threading' do
      it 'fetches records using multiple threads' do
        main_thread = Thread.current

        # extra check to avoid succeeding with a false positive
        test_hit = false
        WebMock.after_request do |request_signature, _|
          if request_signature.uri.to_s.start_with?(base_redirect_url)
            test_hit = true
            expect(Thread.current).to_not be(main_thread)
          end
        end

        subject.records.to_a

        expect(test_hit).to be true
      end
    end
  end
end
