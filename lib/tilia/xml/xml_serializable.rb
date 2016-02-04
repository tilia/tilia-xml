module Tilia
  module Xml
    # Objects implementing XmlSerializable can control how they are represented in
    # Xml.
    module XmlSerializable
      # The xmlSerialize method is called during xml writing.
      #
      # Use the $writer argument to write its own xml serialization.
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
      end
    end
  end
end
