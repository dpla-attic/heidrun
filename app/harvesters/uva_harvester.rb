##
# A harvester implementation for UVA
#
class UVAHarvester
  include Krikri::Harvester

  DEFAULT_URI_TEMPLATE =
    'http://fedoraproxy.lib.virginia.edu/fedora/objects/[PID]/methods/uva-lib%3AmetsSDef/getMETS'
  DEFAULT_THREAD_COUNT = 10
  DEFAULT_HARVEST_NAME = 'virginia'
  DEFAULT_MAX_RECORDS = 0

  ##
  # Initialize, and set default options as appropriate.
  #
  # @param opts [Hash] a hash of options as defined by {.expected_opts}
  #
  # @example
  #    Explicitly set the URI:
  #      UVAHarvester.new(uri: 'http://example.edu/fedora/...')
  #
  #    Or use the default URI and specify collection PIDs to harvest:
  #      UVAHarvester.new(:uva => {:collections => ['uva-lib:744806', 'uva-lib:817985']})
  #
  # Accepts options passed as `:uva => opts`
  #
  # Options allowed are:
  #
  #   - uri:         See Krikri::Harvester#initialize.
  #                  Optional if collection array provided
  #   - name:        See Krikri::Harvester#initialize.
  #                  Defaults to "virginia"
  #   - uva:
  #     - collections  An array of collection PIDs to harvest
  #     - threads:     The number of records to fetch asynchronously
  #                    in a batch (default: 10)
  #     - max_records: The maximum number of records to harvest
  #                    0 means no limit (default 0)
  #
  def initialize(opts = {})
    opts[:uri] ||= DEFAULT_URI_TEMPLATE
    opts[:name] ||= DEFAULT_HARVEST_NAME
    @opts = opts.fetch(:uva, {})
    super

    @opts[:threads] ||= DEFAULT_THREAD_COUNT
    @opts[:max_records] ||= DEFAULT_MAX_RECORDS

    @collection_uris = get_collection_uris(opts[:uri], @opts[:collections])

    if @collection_uris.empty?
      fail 'Please provide a URI or a list of collection PIDs'
    end

    @collection_harvesters = @collection_uris.map do |uri|
      UVACollectionHarvester.new(uri, @opts[:threads], @opts[:max_records],
                                 @record_class, @id_minter, @name)
    end
  end

  ##
  # Work out the list of collection uris
  def get_collection_uris(uri, collections = [])
    if (collections == nil || collections.empty?)
      [uri]
    else
      collections.map { |c| uri.gsub('[PID]', c) }
    end
  end

  ##
  # @see Krikri::Harvester.expected_opts
  def self.expected_opts
    {
      key: :uva,
      opts: {
        collections: { type: :string, multiple_ok: true, required: false },
        threads:  { type: :integer, required: false },
        max_records:  { type: :integer, required: false }
      }
    }
  end

  ##
  # @see Krikri::Harvester#count
  def count
    result = 0
    @collection_harvesters.each { |harv| result += harv.count }
    result
  end

  ##
  # @return [Enumerator] an enumerator of the records targeted by this
  #   harvester.
  def records
    Enumerator.new do |en|
      all_collections = @collection_harvesters.map { |harv| harv.records }

      all_collections.each do |collection|
        collection.each do |record|
          en << record
        end
      end
    end
  end

  ##
  # @param identifier [#to_s] the identifier of the record to get
  # @return [#to_s] the record
  def get_record(identifier)
    @collection_harvesters.each do |harv|
      rec = harv.get_record(identifier)
      break rec if rec
    end
  end

  ##
  # Harvester for a single collection
  class UVACollectionHarvester
    include Krikri::Harvester

    def initialize(uri, threads, max_records, record_class,
                   id_minter, harvester_name)
      @uri = uri
      @threads = threads
      @max_records = max_records
      @record_class = record_class

      # Krikri::Harvester#mint_id expects to find the @id_minter and @name
      # instance variables, so we pass them along here.
      @id_minter = id_minter
      @name = harvester_name

      @http = Krikri::AsyncUriGetter.new
    end

    ##
    # @see Krikri::Harvester#count
    def count
      Integer(records_mets.count)
    end

    ##
    # @return [Enumerator::Lazy] an enumerator of the records targeted by this
    #   harvester.
    def records
      batch_size = @threads
      max_records = @max_records
      last_record = max_records == 0 ? count : [count, max_records].min

      (0...last_record - 1).step(batch_size).lazy.flat_map do |offset|
        enumerate_records(records_mets[offset, batch_size])
      end
    end

    ##
    # @param identifier [#to_s] the identifier of the record to get
    # @return [#to_s] the record
    def get_record(identifier)
      enumerate_records(collection_mets
                          .xpath("//mets:dmdSec[@ID=\"#{identifier}\"]")).first
    end

    private

    ##
    # Get a batch of records
    # @param mets [Nokogiri] the parsed mets for the records to get
    # @return [Array] an array of @record_class instances
    def enumerate_records(mets)
      batch = []
      mets.each do |rec|
        uri = rec.xpath('mets:mdRef').first.attribute('href').value
        batch << { record_uri: uri,
                   request: @http.add_request(uri: URI.parse(uri)) }
      end

      batch.flat_map do |record|
        record[:request].with_response do |response|
          unless response.status == 200
            msg = "Couldn't get record from URI #{record[:record_uri]}"
            Krikri::Logger.log(:error, msg)
            next []
          end
          mods = Nokogiri::XML(response.body)

          mods.child.add_child('<extension />')[0]
            .add_child(collection_mods.xpath('//mods:dateIssued').to_xml)

          record_id = extract_record_id(record[:record_uri], mods)

          Krikri::Logger.log(:debug, "Extracted record ID #{record_id}")
          @record_class.build(mint_id(record_id), mods.to_xml)
        end
      end
    end

    ##
    # Pull the record ID from the (several) places in the MODS record it might
    #   appear.
    # @param mods [Nokogiri] the parsed MODS record
    # @return [String] the identifier for the record
    # @raise [RuntimeError] if a suitable identifier could not be found
    def extract_record_id(identifier, mods)
      # If there's a suitable identifier element, take its value.
      id_element = mods.xpath('/mods:mods/mods:identifier[@type="uri"]').first

      # Otherwise, look for a "primary display" URL.  This will give us a whole
      # URL like:
      #
      #   http://search.lib.virginia.edu/catalog/uva-lib:330187
      #
      # rather than a short identifier like:
      #
      #   uva-lib:1234
      #
      # but this appears to be consistent with what the original harvester did.
      id_element ||= mods.xpath('/mods:mods/mods:location/' \
                                'mods:url[@usage="primary display"]')

      if !id_element || id_element.text.blank?
        msg = "Failed to extract record ID from URI: #{identifier}"
        Krikri::Logger.log(:error, msg)
        fail msg
      end

      id_element.text.strip
    end

    ##
    # Only download and parse the collection level mets file once
    # @return [Nokogiri] the collection mets file, parsed
    def collection_mets
      return @collection_mets if @collection_mets

      @http.add_request(uri: URI.parse(@uri)).with_response do |response|
        unless response.status == 200
          msg = "Couldn't get collection mets file #{@uri}"
          Krikri::Logger.log(:error, msg)
          fail msg
        end

        @collection_mets = Nokogiri::XML(response.body)
      end
    end

    def collection_mods
      return @collection_mods if @collection_mods

      mods_ref = collection_mets
        .xpath('//mets:dmdSec[@ID="collection-description-mods"]')
        .first
      uri = mods_ref.xpath('mets:mdRef').first.attribute('href').value

      @http.add_request(uri: URI.parse(uri)).with_response do |response|
        unless response.status == 200
          msg = "Couldn't get collection mods file #{uri}"
          Krikri::Logger.log(:error, msg)
          fail msg
        end

        @collection_mods = Nokogiri::XML(response.body)
      end
    end

    def records_mets
      return @records_mets if @records_mets

      @records_mets =
        collection_mets
        .xpath('//mets:dmdSec[@ID!="collection-description-mods"]')
    end
  end
end
