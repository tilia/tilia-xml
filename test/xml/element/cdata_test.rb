require 'test_helper'

module Tilia
  module Xml
    class CDataTest < Minitest::Test
      def test_deserialize
        input = <<BLA
<?xml version="1.0"?>
<root xmlns="http://sabredav.org/ns">
 <blabla />
</root>
BLA
        reader = Reader.new
        reader.element_map = { '{http://sabredav.org/ns}blabla' => Element::Cdata }
        reader.xml(input)
        assert_raises(RuntimeError) { reader.parse }
      end

      def test_serialize
        writer = Writer.new
        writer.namespace_map = { 'http://sabredav.org/ns' => nil }
        writer.open_memory
        writer.start_document
        writer.set_indent(true)
        writer.write('{http://sabredav.org/ns}root' => Element::Cdata.new('<foo&bar>'))
        output = writer.output_memory

        expected = <<XML
<?xml version="1.0"?>
<root xmlns="http://sabredav.org/ns"><![CDATA[<foo&bar>]]></root>
XML

        assert_equal(expected, output)
      end
    end
  end
end
