module Heidrun
  module MappingTools
    ##
    # Static methods manipulating files and filenames
    #
    module File
      module_function

      ##
      # @param [String] A filename with an extension
      # @return [String] A mime type like 'image/jpeg'
      def extension_to_mimetype(path)
        extension = path.split('.')[-1]
        Rack::Mime.mime_type(".#{extension}", nil)
      end
    end
  end
end
