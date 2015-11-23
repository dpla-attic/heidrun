module Heidrun
  module MappingTools
    ##
    # Static methods for evaluations and assignments that can be shared between
    # mappings of MARC providers.
    #
    module MARC
      require_relative 'marc/genre'
      require_relative 'marc/dctype'
      require_relative 'marc/dcformat'

      module_function

      ##
      # Given options representing leader and controlfield values, return an
      # array of applicable genre (edm:hasType) controlled-vocabulary terms
      #
      # Options are as follows, and are all Strings:
      #   - leader:  value of MARC 'leader' element
      #   - cf_007:  value of MARC 'controlfield' with 'tag' attribute '007'
      #   - cf_008:  value of MARC 'controlfield' with 'tag' attribute '008'
      #   - cf_970a:  TODO
      #
      # @param opts [Hash] Options, as outlined above
      # @return [Array]
      # @todo: insert handling of optional cf_970a for Hathi, as the first
      # evaluation.
      def genre(opts)
        genres = []

        [:language, :musical_score, :manuscript, :maps, :projected, :two_d, 
         :nonmusical_sound, :musical_sound].each do |genre_type|
          genres = Genre.send(genre_type, opts)
          break unless genres.empty?
        end

        genres << 'Government Document' if
          Genre.government_document?(opts[:cf_008])

        genres
      end

      ##
      # @param opts [Hash] a hash containing MARC `:leader`, `:cf_007`, and/or, 
      #   `df_337a` keys
      # @return [Array<String>] an array of type strings
      def dctype(opts)
        [].concat(DCType.get_337a(opts))
          .concat(DCType.get_type(opts))
      end

      def dcformat(opts)
        Array(DCFormat.from_leader(opts))
          .concat(DCFormat.from_cf007(opts))
      end

      ##
      # Return a lambda suitable for Array#select, that gives the XML element
      # with a particular name and 'tag' attribute.
      #
      # @example matching a field named 'controlfield' with tag '007'
      #   r.node.children
      #     .select(&name_tag_condition('controlfield', '007'))
      #
      # @example matching with a regexp
      #   r.node.children
      #     .select(&name_tag_condition('controlfield', '/^\d{3}$/'))
      #
      # @param name [String] The element name, without the namespace
      # @param tag  [String, Regexp] The value of the element's 'tag' attribute
      # @return [Proc] a proc accepting a `ParserValue`.
      def name_tag_condition(name, tag)
        lambda do |node| 
          return false unless node.name == name
          tag.is_a?(Regexp) ? (node[:tag] =~ tag) : (node[:tag] == tag)
        end
      end

      ##
      # Return a lambda suitable for Array#select, that gives the XML element
      # for a datafield's subfield that has a particular code
      #
      # @param name [String] The element name, without the namespace
      # @param code  [String] The value of the element's 'code' attribute
      def subfield_code_condition(code)
        lambda { |node| node.name == 'subfield' && node[:code] == code }
      end

      ##
      # Return an Array of Element for the datafield with the given number
      # (tag)
      #
      # @param r    [Krikri::XmlParser::Value] The record root element
      # @param name [String] The XML element name, without the namespace
      # @param tag  [String, Regexp] The value of the element's 'tag' attribute,
      #                             or a Regexp to match it
      # @return     [Array] of Element
      def select_field(r, name, tag)
        r.node.children.select(&name_tag_condition(name, tag))
      end

      ##
      # Return an Element for the datafield with the given number (tag)
      #
      # @param r   [Krikri::XmlParser::Value] The record root element
      # @param tag [String|Regexp] The tag, e.g. '240' or /^78[07]$/
      # @return    [Array] of Element, per .select_field
      def datafield_els(r, tag)
        select_field(r, 'datafield', tag)
      end

      ##
      # Return the String value of the datafield with the given number (tag)
      #
      # An empty array is returned if the datafield does not exist.
      #
      # @param  r   [Krikri::XmlParser::Value] The record root element
      # @param  tag [String] The tag, e.g. '001'
      # @return     [Array] of String ([] if element does not exist)
      def datafield_values(r, tag)
        select_field(r, 'datafield', tag).map { |f| f.children.first.to_s }
      end

      ##
      # Return the String values of the controlfields with the given number
      # (tag)
      #
      # @param  r   [Krikri::XmlParser::Value] The record root element
      # @param  tag [String]  The tag, e.g. '007'
      # @return     [Array] of String
      # @raise      [NoElementError]  If the controlfield doesn't exist
      def controlfield_values(r, tag)
        values = select_field(r, 'controlfield', tag).map do |f|
          f.children.first.to_s
        end
        raise NoElementError.new "No control field #{tag}" if values.empty?
        values
      end

      ##
      # Return an Element for the MARC leader
      #
      # @param   r [Krikri::XmlParser::Value] The record root element
      # @return    [String]
      # @raise     [NoElementError]  If there is no leader
      def leader_value(r)
        r.node.children.select { |n| n.name == 'leader' }
                       .first.children.first.to_s
      rescue NoMethodError
        raise NoElementError.new "No MARC leader element"
      end

      ##
      # Return the String value of the subfield element with the given code
      #
      # An empty array is returned if the subfield can not be found.
      #
      # @param  elements [Element] The elements, e.g. datafield
      # @param  code     [String]  Code, i.e. its 'tag' attribute
      # @return          [Array]  ([] if the subfield can not be found)
      def subfield_values(elements, code)
        elements.map do |e|
          nodes = e.children.to_a.select(&subfield_code_condition(code))
          !nodes.empty? ? nodes.first.children.first.to_s : nil
        end.compact
      end

      ##
      # Return an array of Strings for the values of all of the subfields in
      # the given element that have a-z codes
      #
      # @param element [Element] The element, which is probably a datafield
      # @return        [Array]   An array of String.  Empty if no subfields.
      def all_subfield_values(elements)
        # Take all elements that respond to :children, leaving out '\n' nodes,
        # for instance.
        elements.select { |el| el.respond_to?(:children) }.map do |el|
          el.children.to_a
            .select { |child| child.name == 'subfield' \
                              && child[:code] =~ /^[a-z]$/ }
            .map { |child| child.children.first.to_s }
        end.flatten
      end

      ##
      # Whether Control Field 007 indicates Film / Video
      # @param s [String] Control Field 007
      def film_video?(s)
        s[0] == 'v' || (s[0] == 'g' && %w(c d f o).include?(s[1]))
      end

      class NoElementError < StandardError; end
    end  # module MARC
  end  # module MappingTools
end  # module Heidrun
