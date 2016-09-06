##
# A harvester for CDL's Solr API-endpoint
#
# @example
#   To use this harvester you must provide a CaliSphere API key. Information
#   about getting an API key is available here:
#   https://registry.cdlib.org/documentation/docs/technical/solr-api/
#
#   opts = { :api=>{ :'X-Authentication-Token'=>'api-key' } }
#
#   Additional parameters can be included under 'params'.
#   opts = {:api=>{ params: { q:'*:*' },:'X-Authentication-Token'=>'api-key'}}
#
# @see Krikri::Harvesters::ApiHarvester
class CdlHarvester < Krikri::Harvesters::ApiHarvester
 include Krikri::Harvester
  attr_reader :opts

  ##
  #
  # @param opts [Hash] options for the harvester
  # @see .expected_opts
  def initialize(opts = {})
    opts[:uri] ||= 'https://solr.calisphere.org/solr/query'
    opts[:name] ||= 'cdl'
    super
    # Default query parameter excludes dataset records
    @opts['params'] ||= { 'q' => '-type_ss:dataset' }
  end

  ##
  # @return [Hash] A hash documenting the allowable options to pass to
  #   initializers.
  #
  # Http headers are passed in at the same level as params inside
  # the opts hash.
  #
  # @see Krikri::Harvester::expected_opts
  def self.expected_opts
    {
      key: :api,
        opts: {
          :'X-Authentication-Token' => { type: :string, required: true },
          :params => { type: :string, required: false }
       }
    }
  end

  private

  ##
  # Overrides ApiHarvester.get_identifier because the idenitifer field
  # for CDL is different from MDL's.
  #
  # @param doc [Hash] a raw Solr document with an identifier
  #
  # @return [String] the provider's identifier for the document
  def get_identifier(doc)
    doc['id']
  end
end
