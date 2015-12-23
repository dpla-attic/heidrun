require 'json'

##
# A harvester implementation for Internet Archive
#
class IaHarvester
  include Krikri::Harvester

  DEFAULT_THREAD_COUNT = 10
  DEFAULT_MAX_RECORDS = 0

  DOWNLOAD_BASE_URI = 'http://archive.org/download'

  ##
  # Initialize, and set default options as appropriate.
  #
  # @param opts [Hash] a hash of options as defined by {.expected_opts}
  #
  # @example
  #    Typical instantiation, good for most cases:
  #
  #      Krikri::Harvesters::IaHarvester.new(uri: 'http://archive.org/...')
  #
  # Accepts options passed as `:ia => opts`
  #
  # Options allowed are:
  #
  #   - threads:     The number of records to fetch asynchronously
  #                  in a batch (default: 10)
  #   - name:        See Krikri::Harvester#initialize.  Defaults to "ia"
  #   - max_records: The maximum number of records to harvest
  #                  0 means no limit (default 0)
  #
  def initialize(opts = {})
    @opts = opts.fetch(:ia, {})
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
        threads:  { type: :integer, required: false },
        max_records:  { type: :integer, required: false }
      }
    }
  end

  ##
  # @see Krikri::Harvester#count
  def count
    Integer(collection_search['response']['numFound'])
  end

  ##
  # @return [Enumerator::Lazy] an enumerator of the records targeted by this
  #   harvester.
  def records
    threads = @opts.fetch(:threads)
    max_records = @opts.fetch(:max_records)
    last_record = max_records == 0 ? count : [count, max_records].min

    (0...last_record - 1).step(threads).lazy.flat_map do |offset|
      enumerate_records(record_ids(start: offset, rows: threads))
    end
  end

  ##
  # @param identifier [#to_s] the identifier of the record to get
  # @return [#to_s] the record
  def get_record(identifier)
    enumerate_records([identifier]).first
  end

  private

  ##
  # Get a batch of records
  # @param identifiers [Array] identifiers for the docs to get
  # @return [Array] an array of @record_class instances
  def enumerate_records(identifiers)
    batch = []
    identifiers.each do |id|
      meta_uri = "#{DOWNLOAD_BASE_URI}/#{id}/#{id}_meta.xml"

      batch << { :meta_request => @http.add_request(uri: URI.parse(meta_uri)),
                 :id => id }
    end

    batch.each { |r| r[:meta_request].join }

    batch.each do |record|
      record[:meta_request].with_response do |response|
        unless response.status == 200
          msg = "Couldn't get meta for #{record[:id]}, got #{response.status}"
          Krikri::Logger.log(:error, msg)
          next
        end
        record[:meta] = Nokogiri::XML(response.body)
        marc = "#{DOWNLOAD_BASE_URI}/#{record[:id]}/#{record[:id]}_marc.xml"
        record[:marc_request] = @http.add_request(uri: URI.parse(marc))
      end
    end

    batch.select! { |r| r[:meta] }
    batch.each { |r| r[:marc_request].join }

    batch.lazy.map do |record|
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

  ##
  # Get a page of search results for the collection
  # @return [JSON] a page of results containing identifiers for items
  def collection_search(start: 0, rows: @opts[:threads])
    @http.add_request(uri: URI.parse("#{uri}&start=#{start}&rows=#{rows}"))
      .with_response do |response|
      unless response.status == 200
        msg = "Couldn't get search page"
        Krikri::Logger.log(:error, msg)
        # we can't really continue
        raise msg
      end

      JSON.parse(response.body)
    end
  end

  ##
  # Get a page of record identifiers for the collection
  # @return [Array] list of identifiers
  def record_ids(start: 0, rows: @opts[:threads])
    collection_search(start: start, rows: rows)['response']['docs'].map do |d|
      d['identifier']
    end
  end
end
