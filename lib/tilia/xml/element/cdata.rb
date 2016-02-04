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

        # Constructor
        #
        # @param [String] value
        def initialize(value)
          @value = value
        end

        # (see XmlSerializable#xml_serialize)
        def xml_serialize(writer)
          writer.write_cdata(@value)
        end
      end
    end
  end
end
