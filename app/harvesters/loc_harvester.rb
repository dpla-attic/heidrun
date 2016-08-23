##
# Harvester for Library of Congress
# @see krikri::Harvester
class LocHarvester < Krikri::Harvesters::ApiHarvester
  include Krikri::Harvester
  
  # @!attribute [r] opts
  #   @return [Hash<Symbol, Object>] the options for the harvester
  # @see .expected_opts
  attr_reader :opts

  ##
  # @param opts [Hash] options for the harvester
  #   The options for this harvester should be an array of URIs because LoC is
  #   specifying sets of records to be harvested.
  #
  # Initial collections uris:
  #   https://www.loc.gov/collections/american-revolutionary-war-maps/ (1,251 items)
  #   https://www.loc.gov/collections/civil-war-maps/ (1,707 items)
  #   https://www.loc.gov/collections/panoramic-maps/ (1,433 items)
  #
  # @see .expected_opts
  def initialize(opts = {})
    opts[:name] ||= 'loc'
    opts[:api]  ||= {}

    opts[:api][:uris] = Array.wrap(opts[:api][:uris])

    @http = Krikri::AsyncUriGetter.new(opts: {follow_redirects:  true,
                                              inline_exceptions: true})
    super
  end

  ##
  # @return [Hash] A hash documenting the allowable options to pass to
  #   initializers.
  #
  # @see Krikri::Harvester::expected_opts
  def self.expected_opts
    { 
      key: :api,
      opts: {
        uris:          { type: :string, required: true,  multiple_ok: true},
        item_base_uri: { type: :string, required: false, multiple_ok: false}
      }
    }
  end

  ##
  # @param identifier [#to_s] the identifier of the record to get
  # @return [#to_s] the record
  def get_record(identifier)
    build_record(request(build_record_uri(identifier)))
  end

  private

  ##
  # @private
  def build_record_uri(identifier)
    opts[:item_base_uri] + identifier.to_s + '?fo=json'
  end

  ##
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
  # @param response [Hash] a response from the LoC API
  #
  # @return [Integer] value of the number of records in the response
  def get_count(response)
    response['pagination']['of']
  end

  ##
  # @param response [Hash] a response from the LoC API
  #
  # @return [Array] the documents in the response
  def get_docs(response)
    response['results']
  end

  ##
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
  # @return [Enumerator] an enumerator over the records
  def enumerate_records
    Enumerator.new do |yielder|
      # For each of the sets
      opts[:uris].each do |uri|
        loop do
          require 'pry'
          binding.pry
          response = request(uri)
          batch    = get_docs(response)

          break if batch.empty?
          
          batch.each do |item|
            item_uri = Array.new([item['aka'], item['id'], item['url']])
                       .flatten.uniq.grep(/www.loc.gov\/item/).first
                       
            next if item_uri.nil?

            @http.add_request(uri: URI.parse(item_uri + '?fo=json'))
              .with_response do |item_response|
              Krikri::Logger.log(:error, "#{response.status}: #{uri}") unless
                item_response.status == 200
              
              yielder << parse_json(item_response.body)
            end
          end

          uri = next_options(response)
        end
      end
    end
  end

  ##
  # Builds an instance of `@record_class` with the given doc's JSON as
  # content.
  #
  # @param doc [#to_json] the content to serialize as JSON in `#content`
  # @return [#to_s] an instance of @record_class with a minted id and
  #   content the given content
  def build_record(doc)
    @record_class.build(mint_id(get_identifier(doc)),
                        get_content(doc),
                        content_type)
  end

  ##
  # Override request because it needs to support being passed
  # different base URIs. For most LoC requests, there is no need to included
  # options as they provide prebuilt pagination URLs in the feed.
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
  def parse_json(response)
    begin
      JSON.parse(response)
    rescue => e
      Krikri::Logger
        .log(:error, "#{e.message}\n Failed request for #{response.to_s}")
      # If unable to sucessfully parse the response then return nil
      nil
    end
  end
end
