##
# A harvester for NARA's API
#
# @see https://github.com/usnationalarchives/Catalog-API/blob/master/search_and_export.md
# @see Krikri::Harvesters::ApiHarvester
class NaraHarvester < Krikri::Harvesters::ApiHarvester
  DEFAULT_URI = 'https://catalog.archives.gov/api/v1'
  DEFAULT_NAME = 'nara'
  DEFAULT_BATCHSIZE = 10
  DEFAULT_ID_FILENAME = '/var/tmp/nara_ids'
  DEFAULT_PARAMS = {
    'pretty' => 'false',
    'resultTypes' => 'item,fileUnit',
    'objects.object.@objectSortNum' => '1'
  }

  ##
  # Initialize, and set default options as appropriate.
  #
  # @param opts [Hash] a hash of options as defined by {.expected_opts}
  #
  # @example
  #    Typical instantiation, good for most cases:
  #        NaraHarvester.new
  #    Specifying custom parameters:
  #        NaraHarvester.new(api: {'some_query_param' => 'abc'}, batchsize: 15)
  #
  # Parameters to 'opts':
  # - uri:        See Krikri::Harvester#initialize.
  #               Defaults to "https://catalog.archives.gov/api/v1"
  # - name:       See Krikri::Harvester#initialize.  Defaults to "nara"
  # - batchsize:  The number of records to fetch with each API request.
  #               Defaults to 10.
  # - id_fname:   The file name of the Heidrun::IDSource that drives the
  #               harvest and governs which records to fetch.  Defaults to
  #               /var/tmp/nara_ids.
  # - id_fh:      A filehandle to use with Heidrun::IDSource, mostly useful for
  #               automated testing or console usage.  Optional.
  #
  # For other parameters, see Krikri::Harvester#initialize.  
  #
  # Parameters for API requests can be specified with the :api key, but have
  # default values and this should not usually be necessary. See
  # https://github.com/usnationalarchives/Catalog-API/blob/master/search_and_export.md
  #
  # @raise [Errno::ENOENT]  If the IDSource file is missing
  # @raise [Errno::EACCES]  If the IDSource file is unreadable
  #
  def initialize(opts = {})
    opts[:uri] ||= DEFAULT_URI
    opts[:name] ||= DEFAULT_NAME
    batchsize = opts.delete(:batchsize) { DEFAULT_BATCHSIZE }
    # TODO:
    # @id_source is an enumerator over NARA identifiers (naId values).
    # This reads from a file of valid IDs in order to work around the fact that
    # we can not page through NARA's entire result set, due to limitations on
    # the maximum "offset" value in their API.  When they remove this
    # limitation from their API, remove @id_source and refactor this method,
    # #enumerate_records, and #get_count.
    id_fname = opts.delete(:id_source_filename) { DEFAULT_ID_FILENAME }
    id_fh = opts.delete(:id_source_fh) { File.open(id_fname, 'rt') }
    @id_source = Heidrun::IDSource.new(id_fh, batchsize)
    super
    @opts['params'] ||= DEFAULT_PARAMS
  end

  ##
  # @see Krikri::ApiHarvester.expected_opts
  def self.expected_opts
    {
      key: :api,
      opts: {
        params: { type: :hash, required: false},
        id_source_filename: { type: :string, required: false}
      }
    }
  end

  private

  ##
  # @see Krikri::ApiHarvester#enumerate_records
  #
  # TODO:
  # Per the note above in #initialize, when there is no longer an @id_source to
  # drive the harvest, the query options above might want to be amended to pull
  # only those records with "Unrestricted" or "Restricted - Possibly" statuses.
  # We might need to add the following to @opts['params'] in three iterations,
  # where item_type is one of "item", "itemAv", or "fileUnit":
  #      "description.#{item_type}.useRestriction.status.termName" =>
  #        'Unrestricted or "Restricted - Possibly"'
  def enumerate_records
    Enumerator.new do |en|
      request_opts = opts.deep_dup
      @id_source.batches.each do |ids|
        request_opts['params']['naIds'] = ids.join(',')
        begin
          docs = get_docs(request(request_opts.dup))
          break if docs.empty?
          docs.each do |doc|
            en.yield doc
          end
        rescue RestClient::RequestFailed => e
          log :error, "request failed with params #{request_opts['params']}"
          next
        end
      end
    end
  end

  ##
  # @see Krikri::ApiHarvester#get_docs
  def get_docs(response)
    response['opaResponse']['results']['result']
  end

  ##
  # @see Krikri::ApiHarvester#get_identifier
  def get_identifier(doc)
    doc['naId']
  end

  ##
  # @see Krikri::ApiHarvester#get_count
  def get_count(response)
    @id_source.count
  end
end
