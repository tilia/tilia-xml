module Tilia
  module Xml
    module Element
      # 'Elements' is a simple list of elements, without values or attributes.
      # For example, Elements will parse:
      #
      # <?xml version="1.0"?>
      # <s:root xmlns:s="http://sabredav.org/ns">
      #   <s:elem1 />
      #   <s:elem2 />
      #   <s:elem3 />
      #   <s:elem4>content</s:elem4>
      #   <s:elem5 attr="val" />
      # </s:root>
      #
      # Into:
      #
      # [
      #   "{http://sabredav.org/ns}elem1",
      #   "{http://sabredav.org/ns}elem2",
      #   "{http://sabredav.org/ns}elem3",
      #   "{http://sabredav.org/ns}elem4",
      #   "{http://sabredav.org/ns}elem5",
      # ];
      class Elements
        include Element

        # Constructor
        #
        # @param [Array] value
        def initialize(value = [])
          @value = value
        end

        # (see XmlSerializable#xml_serialize)
        def xml_serialize(writer)
          Serializer.enum(writer, @value)
        end

        # (see XmlDeserializable#xml_deserialize)
        def self.xml_deserialize(reader)
          Deserializer.enum(reader)
        end
      end
    end
  end
end
