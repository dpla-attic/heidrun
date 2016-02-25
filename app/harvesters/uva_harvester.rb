##
# A harvester implementation for UVA
#
class UVAHarvester
  include Krikri::Harvester

  DEFAULT_THREAD_COUNT = 10
  DEFAULT_HARVEST_NAME = 'virginia'
  DEFAULT_MAX_RECORDS = 0

  ##
  # Initialize, and set default options as appropriate.
  #
  # @param opts [Hash] a hash of options as defined by {.expected_opts}
  #
  # @example
  #    Typical instantiation, good for most cases:
  #
  #      UVAHarvester.new(uri: 'http://example.edu/fedora/...')
  #
  # Accepts options passed as `:uva => opts`
  #
  # Options allowed are:
  #
  #   - threads:     The number of records to fetch asynchronously
  #                  in a batch (default: 10)
  #   - name:        See Krikri::Harvester#initialize.
  #                  Defaults to "virginia"
  #   - max_records: The maximum number of records to harvest
  #                  0 means no limit (default 0)
  #
  def initialize(opts = {})
    @opts = opts.fetch(:uva, {})
    super

    @opts[:threads] ||= DEFAULT_THREAD_COUNT
    @opts[:name] ||= DEFAULT_HARVEST_NAME
    @opts[:max_records] ||= DEFAULT_MAX_RECORDS

    @http = Krikri::AsyncUriGetter.new
  end

  ##
  # @see Krikri::Harvester.expected_opts
  def self.expected_opts
    {
      key: :uva,
      opts: {
        threads:  { type: :integer, required: false },
        name:  { type: :string, required: false },
        max_records:  { type: :integer, required: false }
      }
    }
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
    batch_size = @opts.fetch(:threads)
    max_records = @opts.fetch(:max_records)
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
      batch << { :request => @http.add_request(uri: URI.parse(uri)),
                 :id => rec.attribute('ID').value }
    end

    batch.lazy.flat_map do |record|
      record[:request].with_response do |response|
        unless response.status == 200
          msg = "Couldn't get record #{record[:id]}"
          Krikri::Logger.log(:error, msg)
          next []
        end
        mods = Nokogiri::XML(response.body)

        mods.child.add_child('<extension />')[0]
          .add_child(collection_mods.xpath('//mods:dateIssued').to_xml)

        @record_class.build(mint_id(record[:id]), mods.to_xml)
      end
    end
  end

  ##
  # Only download and parse the collection level mets file once
  # @return [Nokogiri] the collection mets file, parsed
  def collection_mets
    return @collection_mets if @collection_mets

    @http.add_request(uri: URI.parse(uri)).with_response do |response|
      unless response.status == 200
        msg = "Couldn't get collection mets file"
        Krikri::Logger.log(:error, msg)
        raise msg
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
        msg = "Couldn't get collection mods file"
        Krikri::Logger.log(:error, msg)
        raise msg
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
