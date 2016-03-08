require 'spec_helper'
require 'webmock/rspec'

describe UVAHarvester, :webmock => true do

  let(:base_url) { 'http://example.edu' }
  let(:collection_url) { base_url + '/collection' }
  let(:record1_url) { base_url + '/record1' }
  let(:record2_url) { base_url + '/record2' }
  let(:foo_default_url) { 'http://fedoraproxy.lib.virginia.edu/fedora/objects/uva-lib%3Afoo/methods/uva-lib%3AmetsSDef/getMETS' }
  let(:foo_collection_url) { foo_default_url + '/collection' }

  let(:collection_mets) do
    <<-EOS
    <mets:mets xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
               xmlns:mets="http://www.loc.gov/METS/"
               xmlns:xlink="http://www.w3.org/1999/xlink"
               xsi:schemaLocation="mets http://www.loc.gov/standards/mets/mets.xsd">
       <mets:dmdSec ID="collection-description-mods">
          <mets:mdRef LOCTYPE="PURL" MDTYPE="MODS"
                      xlink:href="#{base_url}/collection"/>
       </mets:dmdSec>
       <mets:dmdSec ID="record1-mods">
          <mets:mdRef LOCTYPE="PURL" MDTYPE="MODS"
                      xlink:href="#{base_url}/record1"/>
       </mets:dmdSec>
       <mets:dmdSec ID="record2-mods">
          <mets:mdRef LOCTYPE="PURL" MDTYPE="MODS"
                      xlink:href="#{base_url}/record2"/>
       </mets:dmdSec>
    </mets:mets>
    EOS
  end

  let(:collection_mods) do
    <<-EOS
    <mods:mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
               xmlns:mods="http://www.loc.gov/mods/v3" version="3.4"
               xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-4.xsd">
       <mods:titleInfo xmlns:xs="http://www.w3.org/2001/XMLSchema">
          <mods:title>The Papers of Donald Duck</mods:title>
       </mods:titleInfo>
       <mods:titleInfo xmlns:xs="http://www.w3.org/2001/XMLSchema" type="alternative">
          <mods:title>Donald Duck Papers</mods:title>
       </mods:titleInfo>
       <mods:originInfo xmlns:xs="http://www.w3.org/2001/XMLSchema">
          <mods:place>
             <mods:placeTerm type="code" authority="marccountry">xx</mods:placeTerm>
          </mods:place>
          <mods:dateIssued keyDate="yes">1934</mods:dateIssued>
          <mods:issuance>monographic</mods:issuance>
          <mods:frequency/>
       </mods:originInfo>
    </mods:mods>
    EOS
  end

  let(:record1_mods) do
    <<-EOS
    <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns:mods="http://www.loc.gov/mods/v3"
          xmlns="http://www.loc.gov/mods/v3"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-3.xsd">
       <titleInfo>
          <title>Letter from Mickey Mouse</title>
       </titleInfo>
    </mods>
    EOS
  end

  let(:record2_mods) do
    <<-EOS
    <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns:mods="http://www.loc.gov/mods/v3"
          xmlns="http://www.loc.gov/mods/v3"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-3.xsd">
       <titleInfo>
          <title>Letter from Scrooge McDuck</title>
       </titleInfo>
    </mods>
    EOS
  end

  subject do
    opts = { uri: base_url }
    UVAHarvester.new(opts)
  end

  before(:each) do
    stub_request(:get, base_url)
      .to_return(status: 200, body: collection_mets, headers: {})
    stub_request(:get, collection_url)
      .to_return(status: 200, body: collection_mods, headers: {})
    stub_request(:get, record1_url)
      .to_return(status: 200, body: record1_mods, headers: {})
    stub_request(:get, record2_url)
      .to_return(status: 200, body: record2_mods, headers: {})
    stub_request(:get, foo_default_url)
      .to_return(status: 200, body: collection_mets, headers: {})
    stub_request(:get, foo_collection_url)
      .to_return(status: 200, body: collection_mods, headers: {})
  end

  describe 'collections option' do
    subject do
      opts = { uva: {collections: ['foo']} }
      UVAHarvester.new(opts)
    end

    it 'will take a collections option instead of a uri' do
      expect(subject.count).to eq(2)
    end
  end

  describe '#count' do
    it 'counts records' do
      expect(subject.count).to eq(2)
    end
  end

  describe '#records' do
    let(:doc) { Nokogiri::XML(subject.records.first.content) }

    it 'fetches a record' do
      expect(doc.xpath('//mods:mods/mods:titleInfo/mods:title')[0].text)
        .to eq('Letter from Mickey Mouse')
    end

    it 'includes the collection dateIssued element as an extension element' do
      expect(doc.xpath('//mods:mods/mods:extension/mods:dateIssued')[0].text)
        .to eq('1934')
    end

    it 'fetches all documents' do
      expect(subject.records.count).to eq(2)
    end

    it 'keeps going after hitting a bad record' do
      stub_request(:get, "#{base_url}/record1")
        .to_return(status: 500, body: 'disaster strikes!', headers: {})

      expect(subject.records.count).to eq(1)
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
