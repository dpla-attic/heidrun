require 'net/http'
require 'rubygems/package'
require 'zlib'

##
# A harvester for Hathi Trust MARC XML dump files.
#
# Supports either harvesting a previously downloaded dump file, or downloading
# the latest available dump file and harvesting that.
#
# @example
#   Specifying a downloaded file.  Note that `uri` is not a URI (e.g.
#   "file:// ...")
#
#   HathiHarvester.enqueue({
#     uri: '/home/dpla/data/hathi/dpla_full_20160201.tar.gz'
#   });
#
# @example
#   Providing the downloads page and letting the harvester pick.  We provide
#   a URL to the "downloads" HTML page, and the harvester finds the most
#   recent file based on its filename.
#
#   HathiHarvester.enqueue({
#     uri: 'http://example.tld/path/to/dpla_metadata/'
#   })
#
class HathiHarvester < Krikri::Harvesters::MarcXMLHarvester
  ##
  # @see Krikri::Harvesters::MarcXMLHarvester#each_collection
  def each_collection
    tarball_source do |tar_file|
      each_tar_entry(tar_file) do |entry|
        yield entry
      end
    end
  end

  private

  ##
  # @yield [IO] Give an IO stream containing an archive of MARC XML collection
  #   files in TAR format.
  def tarball_source(&block)
    if File.exist?(uri)
      File.open(uri, &block)
    elsif URI.parse(uri).instance_of?(URI::Generic)
      fail IOError, "'#{uri}' doesn't exist as a file and isn't a valid URL."
    else
      download_url(latest_tarball_url, &block)
    end
  end

  ##
  # Return the URL of the most recent Hathi data dump
  #
  # `@uri` is expected to be a URL to the _index page_ that lists the
  # gzipped tarball files.
  #
  # @return [URI] The URL of the .tar.gz file
  def latest_tarball_url
    html = Net::HTTP.get(URI(uri))
    parsed_html = Nokogiri::HTML(html)

    file_names = parsed_html.xpath('//a[contains(@href, "dpla_full")]')
                 .map { |a| a.get_attribute('href') }
    latest_file = file_names.sort.reverse.first

    URI.join(uri, latest_file)
  end

  ##
  # Download the contents of a URL to a temporary file.
  #
  # @yield [File] If a block is given, the temporary file will be provided and
  #   removed when the block returns.
  # @return [File] If no block is given, return the temporary file.  The caller
  #   must call #unlink once finished with the file.
  def download_url(url)
    Net::HTTP.start(url.host, url.port) do |http|
      request = Net::HTTP::Get.new(url.request_uri)

      # Make sure the HTTP client doesn't handle the gzip compression on our
      # behalf.  We'll take care of it when we're streaming the temp file.
      #
      request['Accept-Encoding'] = 'identity'

      # Force ASCII decoding to ensure we're working with plain bytes.  Without
      # this, we throw exceptions on bytes with the high bit set:
      #
      # Encoding::UndefinedConversionError: "\x8B" from ASCII-8BIT to UTF-8 file
      #
      file = Tempfile.new('hathi', Dir.tmpdir, encoding: 'ASCII-8BIT')

      http.request(request) do |resp|
        resp.read_body do |seg|
          file.write(seg)
        end
      end

      file.close

      if block_given?
        begin
          yield file
        ensure
          file.unlink
        end
      else
        file
      end
    end
  end

  ##
  # @yield [IO] Provide the stream of each XML entry in a Tar file to the
  #   provided block.
  def each_tar_entry(file)
    Gem::Package::TarReader.new(Zlib::GzipReader.open(file)) do |tar|
      tar.each do |entry|
        if entry.file? && entry.full_name.downcase.end_with?('.xml')
          yield entry
        end
      end
    end
  end
end
