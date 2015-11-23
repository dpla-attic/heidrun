module Heidrun
  module MappingTools
    module MARC
      ##
      # Methods that are used for assigning dc:format values
      #
      module DCFormat

        # Format given by control field 007, position 00,
        # per http://www.loc.gov/marc/bibliographic/bd007.html
        FORMAT_007_00 = {
          'a' => 'Map',
          'c' => 'Electronic resource',
          'd' => 'Globe',
          'f' => 'Tactile material',
          'g' => 'Projected graphic',
          'h' => 'Microform',
          'k' => 'Nonprojected graphic',
          'm' => 'Motion picture',
          'o' => 'Kit',
          'q' => 'Notated music',
          'r' => 'Remote-sensing image',
          's' => 'Sound recording',
          't' => 'Text',
          'v' => 'Videorecording',
          'z' => 'Unspecified'
        }

        # Format given by MARC leader, position 06,
        # per http://www.loc.gov/marc/bibliographic/bdleader.html
        LEADER_06 = {
          'a' => 'Language material',
          'c' => 'Notated music',
          'd' => 'Manuscript notated music',
          'e' => 'Cartographic material',
          'f' => 'Manuscript cartographic material',
          'g' => 'Projected medium',
          'i' => 'Nonmusical sound recording',
          'j' => 'Musical sound recording',
          'k' => 'Two-dimensional nonprojectable graphic',
          'm' => 'Computer file',
          'o' => 'Kit',
          'p' => 'Mixed materials',
          'r' => 'Three-dimensional artifact or naturally occurring object',
          't' => 'Manuscript language material'
        }

        module_function

        def from_leader(opts)
          leader = opts.fetch(:leader) do
            raise NoElementError.new('No string for MARC leader') 
          end

          LEADER_06[leader[6]]
        end

        def from_cf007(opts)
          control_field = opts.fetch(:cf_007) do
            raise NoElementError.new('No string for control field 007')
          end

          control_field.map { |cf| FORMAT_007_00[cf[0]] }.compact
        end
      end  # module DCFormat
    end  # module MARC
  end  # module MappingTools
end  # module Heidrun
