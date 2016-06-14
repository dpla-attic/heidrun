##
# Harvester for Library of Congress
##

class LocHarvester < Krikri::Harvesters::ApiHarvester
 include Krikri::Harvester
  attr_reader :opts

  ##
  #
  # @param opts [Hash] options for the harvester
  # @see .expected_opts
  #
  # The options for this harvester should be an array of URIs because LoC is
  # specifying sets of records to be harvested.
  #
  def initialize(opts = {})
    # https://www.loc.gov/collections/american-revolutionary-war-maps/ (1,251 items)
    # https://www.loc.gov/collections/civil-war-maps/ (1,707 items)
    # https://www.loc.gov/collections/panoramic-maps/ (1,433 items)
    opts[:uri] ||= ['https://www.loc.gov/collections/american-revolutionary-war-maps/?fo=json',
      'https://www.loc.gov/collections/civil-war-maps/?fo=json',
      'https://www.loc.gov/collections/panoramic-maps/?fo=json']
    # TODO add name (check)
    opts[:name] ||= 'loc'
    # Item URI
    opts[:item_uri] ||= 'https://www.loc.gov/item/'
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
       }
    }
  end

  ##
  # @param identifier [#to_s] the identifier of the record to get
  # @return [#to_s] the record
  def get_record(identifier)
    response = request(opts[:item_uri] + identifier.to_s + '?fo=json')
    build_record( response )
  end


  private

  ##
  # @param doc [Hash] the partial item content included in the search result.
  # This content does not include the item's id, only URIs to the various
  # item pages. Aggregate all the URIs and select those that match the
  # JSON-enabled view (www.loc.gov/item/<id>)
  #
  # @return [Hash] the complete record
  def get_item(doc)
    uris = Array.new( [ doc['aka'], doc['id'], doc['url'] ] ).flatten
    .uniq.grep(/www.loc.gov\/item/)
    request(uris.first + '?fo=json') if !uris.empty?
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
      uri.each do | request_opts |
        loop do
          break if request_opts.nil?
          response = request(request_opts)
          docs = get_docs(response)
          break if docs.empty?

          # Queue #get_items threads
          threads = []
          docs.each do |r|
            threads << Thread.new{ get_item(r) }
          end

          # Process threads and only build record if item is not nil
          threads.each do |t|
            item = t.join.value
            yielder << item if !item.nil?
          end
          request_opts = next_options(response)
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
  # none provided
  #
  # @return
  def request(request_uri, request_opts=nil)
    parsed_uri = URI(request_uri)
    # Coerce a scheme for the request URI if one not does exist
    parsed_uri.scheme = 'http' unless parsed_uri.scheme

    begin
      JSON.parse(RestClient.get(parsed_uri.to_s, request_opts))
    rescue => e
      puts "ERROR: " + e.response
      puts "When attempting to request " + parsed_uri.to_s
      # If unable to sucessfully parse the response then return nil
      nil
    end
  end
end
