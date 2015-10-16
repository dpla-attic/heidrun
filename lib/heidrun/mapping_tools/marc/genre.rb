module Heidrun
  module MappingTools
    module MARC
      ##
      # Methods that are used in assigning genre values
      #
      module Genre

        module_function

        def language(opts)
          genres = []

          return genres unless language_material?(opts[:leader])

          if monograph?(opts[:leader])
            genres << 'Book'
          elsif serial?(opts[:leader])
            opts[:cf_008].each do |cf|
              genres << (newspapers?(cf) ? 'Newspapers' : 'Serial')
            end
          elsif mono_component_part?(opts[:leader])
            genres << 'Book'
          else
            genres << 'Serial'
          end
          
          genres
        end

        def musical_score(opts)
          genres = []
          leader = opts[:leader]

          genres << 'Musical Score' if
            notated_music?(leader) || manu_notated_music?(leader)

          genres
        end

        def manuscript(opts)
          genres = []
          genres << 'Manuscript' if manu_lang_material?(opts[:leader])
          genres
        end

        def maps(opts)
          genres = []
          leader = opts[:leader]

          genres << 'Maps' if cart_material?(leader) || 
                              manu_cart_material?(leader)
          genres
        end

        # projected media
        def projected(opts)
          return [] unless projected_medium?(opts[:leader])
          
          opts[:cf_007].each_with_object([]) do |cf, genres|
            if slide?(cf) || transparency?(cf)
              genres << 'Photograph / Pictorial Works'
            elsif Heidrun::MappingTools::MARC.film_video?(cf)
              genres << 'Film / Video'
            end
          end
        end

        # two-dimensional nonprojectable graphic
        def two_d(opts)
          genres = []

          genres << 'Photograph / Pictorial Works' if 
            two_d_nonproj_graphic?(opts[:leader])
          genres
        end

        def nonmusical_sound(opts)
          genres = []
          genres << 'Nonmusic Audio' if nonmusical_sound?(opts[:leader])
          genres
        end

        def musical_sound(opts)
          genres = []
          genres << 'Music' if musical_sound?(opts[:leader])
          genres
        end

        ##
        # Whether the MARC leader indicates Language Material
        # @param s [String]  MARC leader
        def language_material?(s)
          s[6] == 'a'
        end

        ##
        # Whether the MARC leader indicates Monograph
        # @param s [String] MARC leader
        def monograph?(s)
          s[7] == 'm'
        end

        ##
        # Whether control field 008 indicates Newspapers
        # @param s [String] Control field 008
        def newspapers?(s)
          s[21] == 'n'
        end

        ##
        # Whether the MARC leader indicates Serial
        # @param s [String] MARC leader
        def serial?(s)
          s[7] == 's'
        end

        ##
        # Whether the MARC leader indicates a Monographic Component Part
        # @param s [String] MARC leader
        def mono_component_part?(s)
          s[7] == 'a'
        end

        ##
        # Whether the MARC leader indicates Notated Music
        # @param s [String] MARC leader
        def notated_music?(s)
          s[6] == 'c'
        end

        ##
        # Whether the MARC leader indicates Manuscript Notated Music
        # @param s [String] MARC leader
        def manu_notated_music?(s)
          s[6] == 'd'
        end

        ##
        # Whether the MARC leader indicates Manuscript Language Material
        # @param s [String] MARC leader
        def manu_lang_material?(s)
          s[6] == 't'
        end

        ##
        # Whether the MARC leader indicates Cartographic Material
        # @param s [String] MARC leader
        def cart_material?(s)
          s[6] == 'e'
        end

        ##
        # Whether the MARC leader indicates Manuscript Cartographic Material
        # @param s [String] MARC leader
        def manu_cart_material?(s)
          s[6] == 'f'
        end

        ##
        # Whether the MARC leader indicates Projected Medium
        # @param s [String] MARC leader
        def projected_medium?(s)
          s[6] == 'g'
        end

        ##
        # Whether Control Field 007 indicates Slide
        # @param s [String] Control Field 007
        def slide?(s)
          s[1] == 's'
        end

        ##
        # Whether Control Field 007 indicates Transparency
        # @param s [String] Control Field 007
        def transparency?(s)
          s[1] == 't'
        end

        ##
        # Whether the MARC leader indicates Two-Dimensional Non-Projectable
        # Graphic
        # @param s [String] MARC leader
        def two_d_nonproj_graphic?(s)
          s[6] == 'k'
        end

        ##
        # Whether the MARC leader indicates Nonmusical Sound Recording
        # @param s [String] MARC leader
        def nonmusical_sound?(s)
          s[6] == 'i'
        end

        ##
        # Whether the MARC leader indicates Musical Sound Recording
        # @param s [String] MARC leader
        def musical_sound?(s)
          s[6] == 'j'
        end

        ##
        # Whether Control Field 008 indicates Government Document
        # @param s [String] Control Field 008
        def government_document?(s)
          %w(a c f i l m o s).include?(s[28])
        end
      end  # module Genre
    end  # module MARC
  end  # module MappingTools
end  # module Heidrun
