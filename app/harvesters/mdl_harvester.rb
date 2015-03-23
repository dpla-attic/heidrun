##
# A harvester for MDL's API
#
# @see Krikri::Harvesters::ApiHarvester
class MdlHarvester < Krikri::Harvesters::ApiHarvester
  ##
  # Initialize with MDL's default opts.
  #
  # @param opts [Hash] a hash of options as defined by {.expected_opts}
  def initialize(opts = {})
    opts[:uri] ||= 'http://hub-client.lib.umn.edu/api/v1/records'
    opts[:name] ||= 'mdl'
    super
    @opts['params'] ||= { 'q' => 'tags_ssim:dpla' }
  end
end
