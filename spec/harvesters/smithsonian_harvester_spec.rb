require 'spec_helper'

##
# Helper class for creating a temporary directory with compressed and
# uncompressed XML files.
class SmithsonianDirectory
  attr_reader :path

  def self.open
    dir = new
    begin
      yield dir
    ensure
      dir.close
    end
  end

  def initialize
    @path = Dir.mktmpdir
  end

  def add_uncompressed_file(filename, content)
    File.write(File.join(@path, filename), content)
  end

  def add_compressed_file(filename, content)
    Zlib::GzipWriter.open(File.join(@path, filename)) do |gz|
      gz.write(content)
    end
  end

  def close
    FileUtils.rm_rf(@path)
  end
end

describe SmithsonianHarvester, :webmock => false do

  let(:smithsonian_collection) do
    <<-EOS
<?xml version="1.0" encoding="utf-8"?>
<response>
  <result name="response" numFound="6552" start="0">
    <doc>
      <descriptiveNonRepeating>
        <title_sort>ABCD</title_sort>
        <title label="title">Abcd</title>
        <record_ID>12345</record_ID>
      </descriptiveNonRepeating>
    </doc>
    <doc>
      <descriptiveNonRepeating>
        <title_sort>BCDA</title_sort>
        <title label="title">Bcda</title>
        <record_ID>23451</record_ID>
      </descriptiveNonRepeating>
    </doc>
    <doc>
      <descriptiveNonRepeating>
        <title_sort>CDAB</title_sort>
        <title label="title">Cdab</title>
        <record_ID>34512</record_ID>
      </descriptiveNonRepeating>
    </doc>
    <doc>
      <descriptiveNonRepeating>
        <title_sort>DABC</title_sort>
        <title label="title">Dabc</title>
        <record_ID>45123</record_ID>
      </descriptiveNonRepeating>
    </doc>
  </result>
</response>
    EOS
  end

  it 'reads a mixture of gzipped and non-gzipped files' do
    SmithsonianDirectory.open do |dir|
      dir.add_uncompressed_file('file1.xml', smithsonian_collection)
      dir.add_compressed_file('file2.xml.gz', smithsonian_collection)

      expect(described_class.new(uri: dir.path).records.count).to eq(8)
    end
  end

  it 'ignores case variations in filenames' do
    SmithsonianDirectory.open do |dir|
      dir.add_uncompressed_file('file1.xml', smithsonian_collection)
      dir.add_compressed_file('file2.xml.gz', smithsonian_collection)
      dir.add_compressed_file('file3.XmL.GZ', smithsonian_collection)
      dir.add_uncompressed_file('FILE4.XML', smithsonian_collection)

      expect(described_class.new(uri: dir.path).records.count).to eq(16)
    end
  end

  it 'tolerates empty directories' do
    SmithsonianDirectory.open do |dir|
      expect(described_class.new(uri: dir.path).records.count).to eq(0)
    end
  end
end
