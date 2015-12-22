module Tilia
  module Xml
    module Element
      # CDATA element.
      #
      # This element allows you to easily inject CDATA.
      #
      # Note that we strongly recommend avoiding CDATA nodes, unless you definitely
      # know what you're doing, or you're working with unchangable systems that
      # require CDATA.
      class Cdata
        include XmlSerializable

        protected

        # CDATA element value.
        #
        # @return [String]
        attr_accessor :value

        public

        # Constructor
        #
        # @param [String] value
        def initialize(value)
          @value = value
        end

        # The xml_serialize metod is called during xml writing.
        #
        # Use the writer argument to write its own xml serialization.
        #
        # An important note: do _not_ create a parent element. Any element
        # implementing XmlSerializble should only ever write what's considered
        # its 'inner xml'.
        #
        # The parent of the current element is responsible for writing a
        # containing element.
        #
        # This allows serializers to be re-used for different element names.
        #
        # If you are opening new elements, you must also close them again.
        #
        # @param [Writer] writer
        # @return [void]
        def xml_serialize(writer)
          writer.write_cdata(@value)
        end
      end
    end
  end
end
