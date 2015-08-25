module Heidrun
  module MappingTools
    module MARC
      ##
      # Methods that are used in assigning dctype values
      #
      module DCType

        module_function

        MAP = {
          text:                  %w(a c d t),
          sound:                 %w(i j),
          physical_object:       %w(r),
          collection:            %w(p o),
          interactive_resource:  %w(m),
          still_or_moving_image: %w(e f g k)
        }

        ##
        # Matches type values from MARC Leader and 007. Does not handle `337a` 
        # fields.
        # 
        # @param opts [Hash] a hash containing a `:leader` and optionally a 
        #   `:cf_007` key
        # @param map [Hash<Symbol, Array<String>>] a hash mapping types to leader 
        #   position 6 characters
        # @return [Array<String>] the matched type values
        def get_type(opts, map = MAP)
          return [] unless opts[:leader]

          case opts[:leader][6]
          when *map[:text]
            ['Text']
          when *map[:sound]
            ['Sound']
          when *map[:physical_object]
            ['Physical Object']
          when *map[:collection]
            ['Collection']
          when *map[:interactive_resource]
            ['Interactive Resource']
          when *map[:still_or_moving_image]
            get_still_and_moving_image(opts.fetch(:cf_007, []))
          else []
          end
        end
        
        ##
        # Assign the value of datafield 337$a, if it exists.
        def get_337a(opts)
          opts.fetch(:df_337a, [])
        end

        def get_still_and_moving_image(cf_007)
          cf_007.each_with_object([]) do |cf, types|
            if Heidrun::MappingTools::MARC.film_video?(cf)
              types << 'Moving Image' 
            else
              types << 'Image'
            end
          end.uniq
        end
      end  # module DCType
    end  # module MARC
  end  # module MappingTools
end  # module Heidrun
