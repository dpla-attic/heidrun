require 'uri'
require 'json'

##
# A harvester implementation for Internet Archive
#
class IaHarvester
  include Krikri::Harvester

  DEFAULT_THREAD_COUNT = 10
  DEFAULT_PAGE_SIZE = 1000
  DEFAULT_HARVEST_NAME = 'ia'
  DEFAULT_MAX_RECORDS = 0

  DOWNLOAD_BASE_URI = 'http://archive.org/download'

  ##
  # Initialize, and set default options as appropriate.
  #
  # @param opts [Hash] a hash of options as defined by {.expected_opts}
  #
  # @example
  #
  #    IaHarvester.new(
  #      :uri => 'https://archive.org/services/search/beta/scrape.php'
  #      :ia => {:collections => ['bostonpubliclibrary', 'getty']}
  #    )
  #
  # Accepts options passed as `:ia => opts`
  #
  # Options allowed are:
  #
  #   - uri:         See Krikri::Harvester#initialize.
  #   - name:        See Krikri::Harvester#initialize.  (default: "ia")
  #   - ia:
  #     - collections: An array of collections keys to harvest
  #     - threads:     The number of records to fetch asynchronously
  #                    in a batch (default: 10)
  #     - max_records: The maximum number of records to harvest
  #                    0 means no limit (default 0)
  #
  def initialize(opts = {})
    opts[:name] ||= DEFAULT_HARVEST_NAME
    @opts = opts.fetch(:ia, {})

    collections = @opts.fetch(:collections, [])
    if collections.empty?
      msg = ':collections option is required but missing'
      Krikri::Logger.log(:error, msg)
      fail msg
    else
      # Add query parameters to our base URL
      base_uri = URI.parse(opts[:uri])
      base_uri.query = [base_uri.query,
                        'q=collection:(' + collections.join('%20OR%20') + ')',
                        "size=#{DEFAULT_PAGE_SIZE}"
                       ].compact.join('&')

      opts[:uri] = base_uri.to_s
    end

    super

    @opts[:threads] ||= DEFAULT_THREAD_COUNT
    @opts[:max_records] ||= DEFAULT_MAX_RECORDS

    @http = Krikri::AsyncUriGetter.new(opts: { follow_redirects: true })
  end

  ##
  # @see Krikri::Harvester.expected_opts
  def self.expected_opts
    {
      key: :ia,
      opts: {
        collections: { type: :string, multiple_ok: true, required: true },
        threads: { type: :integer, required: false },
        max_records: { type: :integer, required: false }
      }
    }
  end

  ##
  # @return [Enumerator::Lazy] an enumerator of the records targeted by this
  #   harvester.
  def records
    threads = @opts.fetch(:threads)
    max_records = @opts.fetch(:max_records)

    id_sequence = record_ids

    if max_records > 0
      id_sequence = id_sequence.take(max_records)
    end

    id_sequence.each_slice(threads).lazy.flat_map do |identifiers|
      enumerate_records(identifiers)
    end
  end

  ##
  # @param identifier [#to_s] the identifier of the record to get
  # @return [#to_s] the record
  def get_record(identifier)
    enumerate_records([identifier]).first
  end

  ##
  # @see Krikri::Harvester#record_ids
  def record_ids
    Enumerator.new do |en|
      cursor = nil
      loop do
        cursor_param = cursor ? "&cursor=#{cursor}" : ''
        req_uri = uri + cursor_param
        @http.add_request(uri: URI.parse(req_uri))
          .with_response do |response|
          unless response.status == 200
            msg = "Failed to fetch page of IDs for #{req_uri}"
            Krikri::Logger.log(:error, msg)
            # we can't really continue
            fail msg
          end

          result = JSON.parse(response.body)

          result['items'].each do |item|
            en << item['identifier']
          end

          cursor = result['cursor']
        end

        break unless cursor
      end
    end
  end

  private

  ##
  # Get a batch of records
  # @param identifiers [Array] identifiers for the docs to get
  # @return [Array] an array of @record_class instances
  def enumerate_records(identifiers)
    batch = []
    # get meta.xml for each identifier in the batch
    identifiers.each do |id|
      meta_uri = "#{DOWNLOAD_BASE_URI}/#{id}/#{id}_meta.xml"

      batch << { meta_request: @http.add_request(uri: URI.parse(meta_uri)),
                 id: id }
    end

    # wait for the requests to complete so we don't hit the server
    # harder than intended
    batch.each { |r| r[:meta_request].join }

    # parse meta.xml and send requests for corresponding files.xml
    batch.each do |record|
      Krikri::Logger.log(:debug, "Getting meta XML for #{record[:id]}")
      record[:meta_request].with_response do |response|
        unless response.status == 200
          msg = "Couldn't get meta for #{record[:id]}, got #{response.status}"
          Krikri::Logger.log(:error, msg)
          next
        end
        record[:meta] = Nokogiri::XML(response.body)
        files = "#{DOWNLOAD_BASE_URI}/#{record[:id]}/#{record[:id]}_files.xml"
        record[:files_request] = @http.add_request(uri: URI.parse(files))
      end
    end

    # remove any items from the batch that didn't have a meta.xml
    batch.select! { |r| r[:meta] }

    batch.each { |r| r[:files_request].join }

    # parse files.xml, attach it to meta.xml and send requests for marc.xml
    batch.each do |record|
      Krikri::Logger.log(:debug, "Getting files XML for #{record[:id]}")
      record[:files_request].with_response do |response|
        if response.status == 200
          files = Nokogiri::XML(response.body)
          save_with_opt = Nokogiri::XML::Node::SaveOptions::NO_DECLARATION
          record[:meta].child
            .add_child(files.to_xml(save_with: save_with_opt))
        end
        marc = "#{DOWNLOAD_BASE_URI}/#{record[:id]}/#{record[:id]}_marc.xml"
        record[:marc_request] = @http.add_request(uri: URI.parse(marc))
      end
    end

    batch.each { |r| r[:marc_request].join }

    # parse marc.xml and attach it, then build records
    batch.lazy.map do |record|
      Krikri::Logger.log(:debug, "Getting MARC for #{record[:id]}")
      record[:marc_request].with_response do |response|
        if response.status == 200
          marc = Nokogiri::XML(response.body)
          # removing namespaces to allow xpath to work correctly in the mapper
          marc.remove_namespaces!
          save_with_opt = Nokogiri::XML::Node::SaveOptions::NO_DECLARATION
          record[:meta].child.add_child('<marc />')[0]
            .add_child(marc.to_xml(save_with: save_with_opt))
        end
        @record_class.build(mint_id(record[:id]), record[:meta].to_xml)
      end
    end
  end
end
