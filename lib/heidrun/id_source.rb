
module Heidrun

  ##
  # A source of identifier strings to use in constructing API requests.
  #
  # This is a temporary trick to allow us to get around a limitation
  # in NARA's API: we need to request a list of IDs explicitly because we can't
  # page through their entire result set.  IDSource reads a file and gives us
  # batches of IDs as arrays.
  #
  # File format:  text, with one decimal string per line, with an optional
  # trailing comma; for example:
  #
  # 7441504,
  # 7563000,
  # 12014747,
  # ...
  #
  # The optional trailing comma allows it to have been exported from Excel
  # without any preprocessing, as the Excel-exported file we've encountered
  # has this comma.
  #
  class IDSource

    ##
    # Constructor
    #
    # IDSource is initialized with the filehandle of a file that contains one
    # ID string per line.
    #
    # The batchsize parameter will determine how many records are requested
    # with a single request to the API.
    #
    # @param fh        [IO]    File-like object (File / StringIO)
    # @param batchsize [Fixnum]
    #
    def initialize(fh, batchsize = 10)
      @fh = fh
      @batchsize = batchsize
    end

    ##
    # Return an enumerator of arrays of identifiers.
    # @return [Enumerator]
    def batches
      en = Enumerator.new do |e|
        batch = []
        i = 1
        @fh.each_line do |line|
          batch << line.chomp.delete(',')
          if i % @batchsize == 0
            e.yield batch
            batch = []
          end
          i += 1
        end
        e.yield batch if batch.count > 0  # last one
      end
      en.lazy
    end

    def count
      @fh.count
    end
  end
end
