require 'test_helper'
require 'stringio'

module Tilia
  module Xml
    class ServiceTest < Minitest::Test
      def setup
        @util = Service.new
      end

      def test_get_reader
        elems = { '{http://sabre.io/ns}test' => 'Test!' }

        @util.element_map = elems

        reader = @util.reader
        assert_instance_of(Reader, reader)
        assert_equal(elems, reader.element_map)
      end

      def test_get_writer
        ns = { 'http://sabre.io/ns' => 's' }

        @util.namespace_map = ns
        writer = @util.writer

        assert_instance_of(Writer, writer)
        assert_equal(ns, writer.namespace_map)
      end

      def test_parse
        xml = <<XML
<root xmlns="http://sabre.io/ns">
  <child>value</child>
</root>
XML
        root_element = Box.new('')
        result = @util.parse(xml, nil, root_element)
        assert_equal('{http://sabre.io/ns}root', root_element.value)

        expected = [
          {
            'name'       => '{http://sabre.io/ns}child',
            'value'      => 'value',
            'attributes' => {}
          }
        ]

        assert_equal(expected, result)
      end

      def test_parse_stream
        xml = <<XML
<root xmlns="http://sabre.io/ns">
  <child>value</child>
</root>
XML
        stream = StringIO.new
        stream.write xml
        stream.rewind

        root_element = Box.new('')
        result = @util.parse(stream, nil, root_element)
        assert_equal('{http://sabre.io/ns}root', root_element.value)

        expected = [
          {
            'name'       => '{http://sabre.io/ns}child',
            'value'      => 'value',
            'attributes' => {}
          }
        ]

        assert_equal(expected, result)
      end

      def test_expect
        xml = <<XML
<root xmlns="http://sabre.io/ns">
  <child>value</child>
</root>
XML
        result = @util.expect('{http://sabre.io/ns}root', xml)

        expected = [
          {
            'name'       => '{http://sabre.io/ns}child',
            'value'      => 'value',
            'attributes' => {}
          }
        ]

        assert_equal(expected, result)
      end

      def test_expect_stream
        xml = <<XML
<root xmlns="http://sabre.io/ns">
  <child>value</child>
</root>
XML

        stream = StringIO.new
        stream.write xml
        stream.rewind

        result = @util.expect('{http://sabre.io/ns}root', xml)

        expected = [
          {
            'name'       => '{http://sabre.io/ns}child',
            'value'      => 'value',
            'attributes' => {}
          }
        ]

        assert_equal(expected, result)
      end

      def test_expect_wrong
        xml = <<XML
<root xmlns="http://sabre.io/ns">
  <child>value</child>
</root>
XML
        assert_raises(ParseException) { @util.expect('{http://sabre.io/ns}error', xml) }
      end

      def test_write
        @util.namespace_map = { 'http://sabre.io/ns' => 's' }
        result = @util.write(
          '{http://sabre.io/ns}root',
          '{http://sabre.io/ns}child' => 'value'
        )

        expected = <<XML
<?xml version="1.0"?>
<s:root xmlns:s="http://sabre.io/ns">
 <s:child>value</s:child>
</s:root>
XML
        assert_equal(expected, result)
      end

      def test_parse_clark_notation
        expected = ['http://sabredav.org/ns', 'elem']
        result = Service.parse_clark_notation('{http://sabredav.org/ns}elem')
        assert_equal(expected, result)
      end

      def test_parse_clark_notation_fail
        assert_raises(ArgumentError) { Service.parse_clark_notation('http://sabredav.org/ns}elem') }
      end
    end
  end
end
