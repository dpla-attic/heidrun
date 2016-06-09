require 'spec_helper'

require 'krikri/spec/harvester'

##
# Helper methods for building our test data
module HathiTestHelpers
  def tar_stream(*records)
    result = StringIO.new

    Gem::Package::TarWriter.new(result) do |tar|
      records.each_with_index do |record, i|
        tar.add_file("file_#{i}.xml", 0755) do |io|
          io.write(record)
        end
      end
    end

    result.string
  end

  def gzip(s)
    result = StringIO.new('w')

    gzip = Zlib::GzipWriter.new(result)
    gzip.write(s)
    gzip.close

    result.string
  end
end

describe HathiHarvester, :webmock => true do
  include HathiTestHelpers

  it_behaves_like 'a harvester'

  let(:base_url) { 'http://example.com' }
  let(:target_file) { 'dpla_full_20151101.tar.gz' }

  let(:index_page) do
    <<-EOS
    <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
    <html>
     <head><title>Index of /</title></head>
     <body>
      <h1>Index of /</h1>
      <a href="dpla_full_20151025.tar.gz">dpla_full_20151025.t..&gt;</a>
      <a href="dpla_full_20151101.tar.gz">dpla_full_20151101.t..&gt;</a>
      <a href="dpla_full_20140901.tar.gz">dpla_full_20140901.t..&gt;</a>
     </body>
    </html>
    EOS
  end

  let(:marc_record) do
    <<-EOS
    <collection xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd"
                xmlns="http://www.loc.gov/MARC21/slim">
      <record>
        <controlfield tag="001">12345</controlfield>
      </record>
    </collection>
    EOS
  end

  let(:sample_records) { gzip(tar_stream(marc_record)) }

  describe '#each_collection' do
    let(:harvester) { HathiHarvester.new(uri: base_url) }

    describe 'index page lookup' do
      before(:each) do
        stub_request(:get, base_url)
          .to_return(status: 200, body: index_page, headers: {})

        stub_request(:get, "#{base_url}/#{target_file}")
          .to_return(status: 200, body: sample_records, headers: {})

        @fetched_records = []
        harvester.each_collection do |record|
          @fetched_records << record.read
        end
      end

      it 'fetches the most recent tarball automatically' do
        expect(WebMock).to have_requested(:get, base_url)
        expect(WebMock).to have_requested(:get, "#{base_url}/#{target_file}")
      end

      it 'gets back the records we expect' do
        expect(@fetched_records.first).to match(/controlfield.*1234/)
      end

      it 'disables automatic GZIP decompression' do
        expect(WebMock).to have_requested(:get, "#{base_url}/#{target_file}")
                            .with(headers: { 'Accept-Encoding' => 'identity' })
      end
    end

    it 'accepts a file path' do
      Tempfile.create('hathi_test') do |records|
        records.write(sample_records)
        records.flush

        HathiHarvester.new(uri: records.path).each_collection do |record|
          expect(record.read).to match(/controlfield.*1234/)
        end
      end
    end

    it 'fails on a non-existent file path' do
      expect {
        HathiHarvester.new(uri: '/very/unlikely/to/exist')
          .each_collection { |record| }
      }.to raise_error(IOError)
    end
  end
end
