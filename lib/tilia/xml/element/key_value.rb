module Tilia
  module Xml
    module Element
      # 'KeyValue' parses out all child elements from a single node, and outputs a
      # key=>value struct.
      #
      # Attributes will be removed, and duplicate child elements are discarded.
      # Complex values within the elements will be parsed by the 'standard' parser.
      #
      # For example, KeyValue will parse:
      #
      # <?xml version="1.0"?>
      # <s:root xmlns:s="http://sabredav.org/ns">
      #   <s:elem1>value1</s:elem1>
      #   <s:elem2>value2</s:elem2>
      #   <s:elem3 />
      # </s:root>
      #
      # Into:
      #
      # [
      #   "{http://sabredav.org/ns}elem1" => "value1",
      #   "{http://sabredav.org/ns}elem2" => "value2",
      #   "{http://sabredav.org/ns}elem3" => null,
      # ];
      class KeyValue
        include Element

        # Constructor
        #
        # @param [Array] value
        def initialize(value = [])
          @value = value
        end

        # (see XmlSerializable#xml_serialize)
        def xml_serialize(writer)
          writer.write(@value)
        end

        # (see XmlDeserializable#xml_deserialize)
        def self.xml_deserialize(reader)
          Deserializer.key_value(reader)
        end
      end
    end
  end
end
