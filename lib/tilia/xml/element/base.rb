module Tilia
  module Xml
    module Element
      # The Base XML element is the standard parser & generator that's used by the
      # XML reader and writer.
      #
      # It spits out a simple PHP array structure during deserialization, that can
      # also be directly injected back into Writer::write.
      class Base
        include Element

        # @!attribute [r] _value
        #   @!visibility private
        #
        #   PHP value to serialize.

        # Constructor
        #
        # @param value
        def initialize(value = nil)
          @value = value
        end

        # The xml_serialize metod is called during xml writing.
        #
        # Use the writer argument to write its own xml serialization.
        #
        # An important note: do _not_ create a parent element. Any element
        # implementing XmlSerializable should only ever write what's considered
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
        # This method is called statictly, this is because in theory this method
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
          sub_tree = reader.parse_inner_tree
          sub_tree
        end
      end
    end
  end
end
