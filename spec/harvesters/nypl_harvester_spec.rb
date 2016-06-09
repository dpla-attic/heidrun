require 'spec_helper'

require 'krikri/spec/harvester'

describe NyplHarvester do
  it_behaves_like 'a harvester'
  let(:base_url) { 'http://example.com:80/api/v1' }

  let(:collections_xml) do
    <<-EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <nyplAPI>
      <request>
        <query>All root level uuids</query>
      </request>
      <response>
        <headers>
          <status>success</status>
          <code>200</code>
          <message>ok</message>
        </headers>
        <numResults>2</numResults>
        <uuids>
          <uuid>6681fc20-c52b-012f-4eb1-58d385a7bc34</uuid>
          <uuid>b50ab6f0-c52b-012f-5986-58d385a7bc34</uuid>
        </uuids>
      </response>
    </nyplAPI>
    EOS
  end

  let(:capture_items_xml) do
    <<-EOS
    <?xml version="1.0" encoding="utf-8"?>
    <nyplAPI>
      <request>
        <uuid>6681fc20-c52b-012f-4eb1-58d385a7bc34</uuid>
        <perPage>10</perPage>
        <page>1</page>
        <totalPages>1</totalPages>
        <startTime>Beginning of Time</startTime>
        <endTime>Till Now</endTime>
      </request>
      <response>
        <headers>
          <status>success</status>
          <code>200</code>
          <message>ok</message>
        </headers>
        <numResults>2</numResults>
        <capture>
          <uuid>b619bd97-cd9c-e6d9-e040-e00a1806748c</uuid>
          <imageLinks>
            <imageLink description="Cropped .jpeg (760 pixels on the long side)">http://example.com/imagelink</imageLink>
          </imageLinks>
          <apiUri>#{base_url}/items/mods/b619bd97-cd9c-e6d9-e040-e00a1806748c</apiUri>
          <typeOfResource>still image</typeOfResource>
          <imageID>wf39_000520</imageID>
          <sortString>0000000001|0000000001|0000000001</sortString>
          <itemLink>http://digitalcollections.nypl.org/items/b619bd97-cd9c-e6d9-e040-e00a1806748c</itemLink>
          <dateDigitized>2015-04-06T14:22:25Z</dateDigitized>
          <rightsStatement>rights statement</rightsStatement>
        </capture>
        <capture>
          <uuid>b619bd97-cd9d-e6d9-e040-e00a1806748c</uuid>
          <imageLinks>
            <imageLink description="Cropped .jpeg (760 pixels on the long side)">http://example.com/imagelink</imageLink>
          </imageLinks>
          <apiUri>#{base_url}/items/mods/b619bd97-cd9d-e6d9-e040-e00a1806748c</apiUri>
          <typeOfResource>still image</typeOfResource>
          <imageID>wf39_000521</imageID>
          <sortString>0000000001|0000000002|0000000001</sortString>
          <itemLink>http://digitalcollections.nypl.org/items/b619bd97-cd9d-e6d9-e040-e00a1806748c</itemLink>
          <dateDigitized>2015-04-06T14:22:25Z</dateDigitized>
          <rightsStatement>rights statement</rightsStatement>
        </capture>
      </response>
    </nyplAPI>
    EOS
  end

  let(:mods_item_xml) do
    <<-EOS
    <?xml version="1.0" encoding="utf-8"?>
    <nyplAPI>
      <request>
        <uuid>b619bd97-cd9d-e6d9-e040-e00a1806748c</uuid>
      </request>
      <response>
        <headers>
          <status>success</status>
          <code>200</code>
          <message>ok</message>
        </headers>
        <mods version="3.4" schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-4.xsd">
          <titleInfo lang="eng" supplied="no" usage="primary">
            <title>title</title>
          </titleInfo>
        </mods>
        <rightsStatement>rights</rightsStatement>
      </response>
    </nyplAPI>
    EOS
  end

  subject do
    opts = { uri: base_url, nypl: { apikey: 'notrealkey' } }
    NyplHarvester.new(opts)
  end

  before(:each) do
    stub_request(:get, "#{base_url}/items/roots.xml")
      .to_return(status: 200, body: collections_xml, headers: {})

    stub_request(:get,
                 %r{#{base_url}/items/[0-9a-f-]+\.xml\?page=1&per_page=\d+})
      .to_return(status: 200, body: capture_items_xml, headers: {})

    stub_request(:get, %r{#{base_url}/items/mods/[0-9a-f-]+\.xml})
      .to_return(:status => 200, :body => mods_item_xml, :headers => {})
  end

  describe '#count' do
    it 'counts records' do
      expect(subject.count).to eq(4)
    end
  end

  describe '#records' do
    let(:doc) { Nokogiri::XML(subject.records.first.content) }

    it 'fetches a record' do
      expect(doc.xpath('//mods/titleInfo/title')[0].text).to eq('title')
    end

    it 'includes the capture record as an extension element' do
      expect(doc.xpath('//mods/extension/capture/typeOfResource')[0].text)
        .to eq('still image')
    end

    it 'fetches all documents' do
      expect(subject.records.count).to eq(4)
    end

    it 'skips item records that fail for some reason' do
      stub_request(:get, %r{#{base_url}/items/mods/[0-9a-f-]+\.xml})
        .to_return(:status => 200, :body => mods_item_xml, :headers => {})
        .times(3)
        .to_return(:status => 500, :body => 'disaster strikes!', :headers => {})

      expect(subject.records.count).to eq(3)
    end

    it 'raises an exception on other failed request types' do
      stub_request(:get, "#{base_url}/items/roots.xml")
        .to_return(status: 500, body: 'disaster strikes!', headers: {})

      expect { subject.records.count }.to raise_error(/couldn't fetch/)
    end

    describe 'threading' do
      it 'fetches records using multiple threads' do
        main_thread = Thread.current

        # extra check to avoid succeeding with a false positive
        test_hit = false
        WebMock.after_request do |request_signature, _|
          if request_signature.uri.to_s.start_with?(base_url)
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
