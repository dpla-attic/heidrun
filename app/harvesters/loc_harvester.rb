##
# Harvester for Library of Congress
# @see krikri::Harvester
class LocHarvester
  include Krikri::Harvester

  CONTENT_TYPE         = 'application/json'.freeze
  DEFAULT_THREAD_COUNT = 20.freeze
  JSON_PARAM           = '?fo=json'.freeze
  
  # @!attribute [r] opts
  #   @return [Hash<Symbol, Object>] the options for the harvester
  #   @see .expected_opts
  attr_reader :opts

  ##
  # @param opts [Hash] options for the harvester
  #   The options may be a single URI, or an array of URIs specifying sets of 
  #   records to be harvested.
  #
  # Example collections uris:
  #   https://www.loc.gov/collections/american-revolutionary-war-maps/?fo=json (1,251 items)
  #   https://www.loc.gov/collections/civil-war-maps/?fo=json (1,707 items)
  #   https://www.loc.gov/collections/panoramic-maps/?fo=json (1,433 items)
  #
  # @see .expected_opts
  def initialize(opts = {})
    opts[:uri]    = '' if opts[:loc] # don't require a URI if we have loc opts
    opts[:name] ||= 'loc'.freeze
    
    super(opts)

    @opts = opts.fetch(:loc, {})
    @opts[:uris]            = Array.wrap(@opts[:uris])
    @opts[:item_base_uri] ||= 'https://www.loc.gov/item/'.freeze
    @opts[:threads]       ||= DEFAULT_THREAD_COUNT

    @http = Krikri::AsyncUriGetter.new(opts: { follow_redirects:  true,
                                               inline_exceptions: true })
  end

  ##
  # @return [Hash] A hash documenting the allowable options to pass to
  #   initializers.
  #
  # @see Krikri::Harvester.expected_opts
  def self.expected_opts
    { 
      key: :loc,
      opts: {
        uris:          { type: :string,  required: true,  multiple_ok: true},
        item_base_uri: { type: :string,  required: false, multiple_ok: false},
        threads:       { type: :integer, required: false, multiple_ok: false}
      }
    }
  end
  
  ##
  # @see Krikri::Harvester#content_type
  def content_type
    CONTENT_TYPE
  end

  ##
  # @param identifier [#to_s] the identifier of the record to get
  # @return [#to_s] the record
  def get_record(identifier)
    build_record(request(build_record_uri(identifier)))
  end

  ##
  # @see Krikri::Harvester#record_ids
  def records
    enumerate_records.lazy.map { |rec| build_record(rec) }
  end

  ##
  # @see Krikri::Harvester#record_ids
  def record_ids
    enumerate_uris.map { |u| u.split('/').last }.to_enum
  end

  private

  ##
  # @private
  # @param  identifier [#to_s]
  #
  # @return [RDF::URI]
  def build_record_uri(identifier)
    RDF::URI(opts[:item_base_uri]) / identifier.to_s / JSON_PARAM
  end

  ##
  # @private
  #
  # Overrides ApiHarvester.get_identifier because the idenitifer field
  # for Library of Congress
  #
  # @param doc [Hash] a JSON serialziation with an identifier
  #
  # @return [String] the provider's identifier for the document
  def get_identifier(doc)
    # doc is the response to a request for /item/<id>
    doc['item']['library_of_congress_control_number']
  end

  ##
  # @private
  #
  # @param response [Hash] a response from the LoC API
  #
  # @return [Integer] value of the number of records in the response
  def get_count(response)
    response['pagination']['of']
  end

  ##
  # @private
  #
  # @param response [Hash] a response from the LoC API
  #
  # @return [Array] the documents in the response
  def get_docs(response)
    response['results']
  end

  ##
  # @private
  #
  # Get the URL for the next request.
  #
  # @param opts [Hash] the response to the current request. The next page is
  # provided in the ['next'] element
  #
  # @param response [Hash]
  #
  # @return [Hash] the next request's options hash
  def next_options(response)
    response['pagination']['next']
  end

  ##
  # @private
  #
  # @return [Enumerator] an enumerator over the records
  def enumerate_records
    Enumerator.new do |yielder|
      enumerate_uris.lazy.each_slice(opts[:threads]).each do |uris|
        batch = []

        uris.each do |item_uri|
          batch << @http.add_request(uri: URI.parse(item_uri + JSON_PARAM))
        end
        
        batch.each(&:join)

        batch.each do |request|
          request.with_response do |item_response|
            Krikri::Logger.log(:error, "#{response.status}: #{uri}") unless
              item_response.status == 200
            yielder << parse_json(item_response.body)
          end
        end
      end
    end
  end

  ##
  # @private
  #
  # @return [Enumerator] an enumerator over the record uris
  def enumerate_uris
    Enumerator.new do |yielder|
      # For each of the sets
      opts[:uris].each do |uri|
        loop do
          response = request(uri)
          batch    = get_docs(response)

          next  if batch.nil?
          break if batch.empty?
          
          batch.each do |item|
            item_uri = Array.new([item['aka'], item['id'], item['url']])
                       .flatten.uniq.grep(/www.loc.gov\/item/).first
                       
            yielder << item_uri unless item_uri.nil?
          end

          uri = next_options(response) or break
        end
      end
    end   
  end

  ##
  # @private
  #
  # Builds an instance of `@record_class` with the given doc's JSON as
  # content.
  #
  # @param doc [#to_json] the content to serialize as JSON in `#content`
  # @return [#to_s] an instance of @record_class with a minted id and
  #   content the given content
  def build_record(doc)
    @record_class.build(mint_id(get_identifier(doc)),
                        doc.to_json,
                        content_type)
  end

  ##
  # @private
  #
  # A simple HTTP request without threading.
  #
  # @param request_uri [#to_s] the base URI of the request
  # @param request_opts [Hash] options for the base URI, defaults to nil if
  #   none provided
  def request(request_uri, request_opts=nil)
    parsed_uri = URI(request_uri)
    # Coerce a scheme for the request URI if one not does exist
    parsed_uri.scheme = 'http' unless parsed_uri.scheme

    parse_json(RestClient.get(parsed_uri.to_s, request_opts))
  end

  ##
  # @private
  #
  # @return [Hash, nil] the parsed JSON, or nil if an error is caught and logged
  def parse_json(response)
    begin
      JSON.parse(response)
    rescue => e
      Krikri::Logger
        .log(:error, "Failed to parse response: #{e.message}")
      nil
    end
  end
end
