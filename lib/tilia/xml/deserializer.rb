module Tilia
  module Xml
    # This class provides a number of 'deserializer' helper functions.
    # These can be used to easily specify custom deserializers for specific
    # XML elements.
    #
    # You can either use these functions from within the element_map in the
    # Service or Reader class, or you can call them from within your own
    # deserializer functions.
    module Deserializer
      # The 'keyValue' deserializer parses all child elements, and outputs them as
      # a "key=>value" array.
      #
      # For example, keyvalue will parse:
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
      # ]
      #
      # If you specify the 'namespace' argument, the deserializer will remove
      # the namespaces of the keys that match that namespace.
      #
      # For example, if you call keyValue like this:
      #
      # key_value(reader, 'http://sabredav.org/ns')
      #
      # it's output will instead be:
      #
      # [
      #   "elem1" => "value1",
      #   "elem2" => "value2",
      #   "elem3" => null,
      # ]
      #
      # Attributes will be removed from the top-level elements. If elements with
      # the same name appear twice in the list, only the last one will be kept.
      #
      #
      # @param [Reader] reader
      # @param [String, nil] namespace
      # @return [Hash]
      def self.key_value(reader, namespace = nil)

        # If there's no children, we don't do anything.
        if reader.empty_element?
          reader.next
          return {}
        end

        values = {}

        reader.read
        loop do
          if reader.node_type == ::LibXML::XML::Reader::TYPE_ELEMENT
            if namespace && reader.namespace_uri == namespace
              values[reader.local_name] = reader.parse_current_element['value']
            else
              clark = reader.clark
              values[clark] = reader.parse_current_element['value']
            end
          else
            reader.read
          end

          break if reader.node_type == ::LibXML::XML::Reader::TYPE_END_ELEMENT
        end

        reader.read

        return values
      end


      # The 'enum' deserializer parses elements into a simple list
      # without values or attributes.
      #
      # For example, Elements will parse:
      #
      # <?xml version="1.0"? >
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
      # ]
      #
      # This is useful for 'enum'-like structures.
      #
      # If the namespace argument is specified, it will strip the namespace
      # for all elements that match that.
      #
      # For example,
      #
      # enum(reader, 'http://sabredav.org/ns')
      #
      # would return:
      #
      # [
      #   "elem1",
      #   "elem2",
      #   "elem3",
      #   "elem4",
      #   "elem5",
      # ]
      #
      # @param [Reader] reader
      # @param [String, nil] namespace
      # @return [Array<String>]
      def self.enum(reader, namespace = nil)

        # If there's no children, we don't do anything.
        if reader.empty_element?
          reader.next
          return []
        end

        reader.read
        current_depth = reader.depth

        values = []
        loop do
          unless reader.node_type == ::LibXML::XML::Reader::TYPE_ELEMENT
            break unless reader.depth >= current_depth && reader.next
            next
          end

          if namespace && namespace == reader.namespace_uri
            values << reader.local_name
          else
            values << reader.clark
          end

          break unless reader.depth >= current_depth && reader.next
        end

        reader.next
        return values
      end


      # The valueObject deserializer turns an xml element into a PHP object of
      # a specific class.
      #
      # This is primarily used by the mapValueObject function from the Service
      # class, but it can also easily be used for more specific situations.
      #
      # @param [Reader] reader
      # @param [Class] klass
      # @param [String] namespace
      # @return object
      def self.value_object(reader, klass, namespace)
        value_object = klass.new

        if reader.empty_element?
          reader.next
          return {}
        end

        default_properties = {}
        value_object.instance_variables.each do |name|
          default_properties[name] = value_object.instance_variable_get(name)
        end

        reader.read
        loop do
          if reader.node_type == ::LibXML::XML::Reader::TYPE_ELEMENT && reader.namespace_uri == namespace
            var_name = "@#{reader.local_name}".to_sym
            if default_properties.key?(var_name)
              if default_properties[var_name].is_a?(Array)
                value_object.instance_variable_get(var_name) << reader.parse_current_element['value']
              else
                value_object.instance_variable_set(var_name, reader.parse_current_element['value'])
              end
            else
              # Ignore property
              reader.next
            end
          else
            reader.read
          end

          break unless reader.node_type != ::LibXML::XML::Reader::TYPE_END_ELEMENT
        end

        reader.read
        return value_object
      end

      # This deserializer helps you deserialize xml structures that look like
      # this:
      #
      # <collection>
      #    <item>...</item>
      #    <item>...</item>
      #    <item>...</item>
      # </collection>
      #
      # Many XML documents use  patterns like that, and this deserializer
      # allow you to get all the 'items' as an array.
      #
      # In that previous example, you would register the deserializer as such:
      #
      # reader.element_map['{}collection'] = function(reader) {
      #     return repeating_elements(reader, '{}item')
      # }
      #
      # The repeatingElements deserializer simply returns everything as an array.
      #
      # @param [Reader] reader
      # @param [String] child_element_name Element name in clark-notation
      # @return Array
      def self.repeating_elements(reader, child_element_name)
        result = []

        reader.parse_get_elements.each do |element|
          result << element['value'] if element['name'] == child_element_name
        end

        result
      end
    end
  end
end
