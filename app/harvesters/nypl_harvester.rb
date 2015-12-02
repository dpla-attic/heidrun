##
# A harvester for NYPL's API
#
# @see Krikri::Harvesters::ApiHarvester
class NyplHarvester < Krikri::Harvesters::ApiHarvester
  DEFAULT_URI = 'http://api.repo.nypl.org/api/v1'
  DEFAULT_NAME = 'nypl'
  DEFAULT_BATCHSIZE = 10

  ##
  # Initialize, and set default options as appropriate.
  #
  # @param opts [Hash] a hash of options as defined by {.expected_opts}
  #
  # @example
  #    Typical instantiation, good for most cases:
  #
  #        NyplHarvester.new(apikey: 'somekey')
  #
  #    Limiting the harvest to only certain collections (based on a pattern
  #    matching some or all of the collection UUID):
  #
  #        NyplHarvester.new(apikey: 'somekey', match_collection: /^[abc]/)
  #
  #    The `match_collection` option allows you to target the harvest to
  #    particular roots (see GET /api/v1/items/roots).  The intention is to
  #    allow multiple harvests to run, each harvesting non-overlapping subsets
  #    of records.
  #
  #    For example, you could run 5 harvests with each taking 3 UUID prefixes
  #    (out of the total 15 possible) by providing the following
  #    match_collections to the respective jobs:
  #
  #      match_collection: /^[012]/
  #      match_collection: /^[345]/
  #      match_collection: /^[678]/
  #      match_collection: /^[9ab]/
  #      match_collection: /^[cdef]/
  #
  # Parameters to 'opts':
  #
  # - uri:        See Krikri::Harvester#initialize.
  #               Defaults to "http://api.repo.nypl.org/api/v1'"
  # - name:       See Krikri::Harvester#initialize.  Defaults to "nypl"
  # - batchsize:  The number of records to fetch with each API request.
  #               Defaults to 10.
  #
  def initialize(opts = {})
    opts[:uri] ||= DEFAULT_URI
    opts[:name] ||= DEFAULT_NAME
    super

    @opts[:batchsize] = opts.delete(:batchsize) { DEFAULT_BATCHSIZE }
    @opts[:match_collection] = opts.delete(:match_collection)
    @opts[:apikey] = opts.fetch(:apikey)
  end

  ##
  # @see Krikri::ApiHarvester.expected_opts
  def self.expected_opts
    {
      key: :api,
      opts: {
        params: { type: :hash, required: false },
        batchsize:  { type: :integer, required: false }
      }
    }
  end

  ##
  # @see Krikri::Harvester#count
  def count
    collection_counts = list_collections.map do |collection_uuid|
      request_opts = { page: 1, per_page: 0 }
      response = request("/items/#{collection_uuid}", request_opts)

      Integer(response.xpath('//nyplAPI/response/numResults')[0].text)
    end

    collection_counts.reduce(0) { |a, e| a + e }
  rescue RestClient::RequestFailed
    msg = "request failed with params #{request_opts}"
    Krikri::Logger.log(:error, msg)
    raise
  end

  private

  ##
  # @see Krikri::ApiHarvester#next_options
  #
  # @note Unlike its superclass, this next_options takes the current request
  #   options and the last response returned.  This is because NYPL does the
  #   pagination for us, so there's no need to calculate offsets based on
  #   document counts.
  #
  # @param request_opts [Hash] The options passed to the last request
  # @param last_response [Hash] The last JSON response received
  #
  def next_options(request_opts, last_response)
    this_page = Integer(last_response.xpath('//nyplAPI/request/page').text)
    max_page = Integer(last_response.xpath('//nyplAPI/request/totalPages').text)

    request_opts.merge(page: request_opts[:page] + 1) if this_page < max_page
  end

  ##
  # @see Krikri::ApiHarvester#enumerate_records
  #
  def enumerate_records
    Enumerator.new do |en|
      list_collections.each do |collection_uuid|
        request_opts = { page: 1, per_page: opts[:batchsize] }
        loop do
          begin
            response = request("/items/#{collection_uuid}", request_opts)
            get_docs(response).each { |doc| en << doc }
            request_opts = next_options(request_opts, response)
            break if request_opts.nil?
          rescue RestClient::RequestFailed
            msg = "request failed with params #{request_opts}"
            Krikri::Logger.log(:error, msg)
            next
          end
        end
      end
    end
  end

  ##
  # @see Krikri::ApiHarvester#get_docs
  #
  def get_docs(response)
    response.xpath('//nyplAPI/response/capture').map do |capture_record|
      item_uri = capture_record.xpath('./apiUri').text
      mods_record = request(item_uri + '.xml')
      {
        identifier: capture_record.xpath('./uuid').text,
        item_record: mods_record.xpath('//nyplAPI/response/mods')[0],
        capture_record: capture_record
      }
    end
  end

  ##
  # @see Krikri::ApiHarvester#get_identifier
  #
  def get_identifier(doc)
    doc.fetch(:identifier)
  end

  ##
  # @see Krikri::ApiHarvester#get_content
  #
  def get_content(doc)
    # Since we really need to work with two records here (the item record and
    # the capture record), we combine both into a single original record.  Use
    # the mods `extension` element for this.
    mods_record = doc.fetch(:item_record)
    capture_record = doc.fetch(:capture_record)

    mods_record.add_namespace('mods', 'http://www.loc.gov/mods/v3')

    mods_record
      .add_child('<extension />')[0]
      .add_child(capture_record)

    mods_record.to_xml
  end

  ##
  # @see Krikri::ApiHarvester#content_type
  #
  def content_type
    'text/xml'
  end

  ##
  # Send a request to an NYPL API endpoint and return the `response` section
  #
  # @param endpoint_uri [String] the API endpoint to hit (e.g. '/items/roots')
  # @param request_opts [Hash] options to pass to RestClient
  #
  def request(endpoint_uri, params = {})
    if endpoint_uri.start_with?('/')
      abs_url = "#{uri}#{endpoint_uri}.xml"
    else
      abs_url = endpoint_uri
    end

    # Unfortunately to pass both headers and params you have to use the
    # special `:params` key in the headers hash.
    Nokogiri::XML(RestClient.get(abs_url, headers.merge(params: params)))
  end

  ##
  # @return [Hash] A suitable Authorization header for NYPL
  #
  def headers
    {
      'Authorization' => "Token token=\"#{opts.fetch(:apikey)}\""
    }
  end

  ##
  # @return [Array<String>] A list of collection UUIDs eligible for harvest
  #
  def list_collections
    match_collection = opts[:match_collection] || /.*/

    response = request('/items/roots')
    response.xpath('//nyplAPI/response/uuids/uuid')
      .map(&:text)
      .grep(match_collection)
  end
end
