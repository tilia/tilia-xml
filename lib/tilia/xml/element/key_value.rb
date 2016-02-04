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

        # @!attribute [r] _value
        #   @!visibility private
        #
        #   Value to serialize
        #
        #   @return [Array]

        # Constructor
        #
        # @param [Array] value
        def initialize(value = [])
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
          writer.write(@value)
        end

        # The deserialize method is called during xml parsing.
        #
        # This method is called staticly, this is because in theory this method
        # may be used as a type of constructor, or factory method.
        #
        # Often you want to return an instance of the current class, but you are
        # free to return other data as well.
        #
        # Important note 2: You are responsible for advancing the reader to the
        # next element. Not doing anything will result in a never-ending loop.
        #
        # If you just want to skip parsing for this element altogether, you can
        # just call reader->next();
        #
        # reader->parseInnerTree() will parse the entire sub-tree, and advance to
        # the next element.
        #
        # @param [Reader] reader
        # @return mixed
        def self.xml_deserialize(reader)
          Deserializer.key_value(reader)
        end
      end
    end
  end
end
