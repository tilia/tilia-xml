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

      def test_map_value_object
         input = <<XML
<?xml version="1.0"?>
<order xmlns="http://sabredav.org/ns">
 <id>1234</id>
 <amount>99.99</amount>
 <description>black friday deal</description>
 <status>
  <id>5</id>
  <label>processed</label>
 </status>
</order>
XML

        ns = 'http://sabredav.org/ns'
        order_service = Service.new
        order_service.map_value_object("{#{ns}}order", Xml::Order)
        order_service.map_value_object("{#{ns}}status", Xml::OrderStatus)
        order_service.namespace_map[ns] = nil

        order = order_service.parse(input)
        expected = Order.new
        expected.id = '1234'
        expected.amount = '99.99'
        expected.description = 'black friday deal'
        expected.status = OrderStatus.new
        expected.status.id = '5'
        expected.status.label = 'processed'

        assert_instance_equal(expected, order)

        written_xml = order_service.write_value_object(order)
        assert_equal(input, written_xml)
      end

      def test_write_vo_not_found
        service = Service.new
        assert_raises(ArgumentError) do
          service.write_value_object(Class.new)
        end
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

    # asset for test_map_value_object
    class Order
      attr_accessor :id
      attr_accessor :amount
      attr_accessor :description
      attr_accessor :status

      def initialize
        @id = nil
        @amount = nil
        @description = nil
        @status = nil
      end
    end

    # asset for test_map_value_object
    class OrderStatus
      attr_accessor :id
      attr_accessor :label

      def initialize
        @id = nil
        @label = nil
      end
    end
  end
end
