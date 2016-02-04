require 'test_helper'

module Tilia
  module Xml
    module Deserializer
      class ValueObjectTest < Minitest::Test
        def test_deserialize_value_object
          input = <<XML
<?xml version="1.0"?>
<foo xmlns="urn:foo">
   <firstName>Harry</firstName>
   <lastName>Turtle</lastName>
</foo>
XML

          reader = Reader.new
          reader.xml(input)
          reader.element_map = {
            '{urn:foo}foo' => lambda do |reader|
              return Deserializer.value_object(reader, TestVo, 'urn:foo')
            end
          }

          output = reader.parse

          vo = TestVo.new
          vo.first_name = 'Harry'
          vo.last_name = 'Turtle'

          expected = {
            'name'       => '{urn:foo}foo',
            'value'      => vo,
            'attributes' => []
          }

          assert_instance_equal(
            expected,
            output
          )
        end

        def test_deserialize_value_object_ignored_element
          input = <<XML
<?xml version="1.0"?>
<foo xmlns="urn:foo">
   <firstName>Harry</firstName>
   <lastName>Turtle</lastName>
   <email>harry@example.org</email>
</foo>
XML

          reader = Reader.new
          reader.xml(input)
          reader.element_map = {
            '{urn:foo}foo' => lambda do |reader|
              return Deserializer.value_object(reader, TestVo, 'urn:foo')
            end
          }

          output = reader.parse

          vo = TestVo.new
          vo.first_name = 'Harry'
          vo.last_name = 'Turtle'

          expected = {
            'name'       => '{urn:foo}foo',
            'value'      => vo,
            'attributes' => []
          }

          assert_instance_equal(
            expected,
            output
          )
        end

        def test_deserialize_value_object_auto_array
          input = <<XML
<?xml version="1.0"?>
<foo xmlns="urn:foo">
   <firstName>Harry</firstName>
   <lastName>Turtle</lastName>
   <link>http://example.org/</link>
   <link>http://example.net/</link>
</foo>
XML

          reader = Reader.new
          reader.xml(input)
          reader.element_map = {
            '{urn:foo}foo' => lambda do |reader|
              return Deserializer.value_object(reader, TestVo, 'urn:foo')
            end
          }

          output = reader.parse

          vo = TestVo.new
          vo.first_name = 'Harry'
          vo.last_name = 'Turtle'
          vo.link = [
            'http://example.org/',
            'http://example.net/'
          ]

          expected = {
            'name'       => '{urn:foo}foo',
            'value'      => vo,
            'attributes' => []
          }

          assert_instance_equal(
            expected,
            output
          )
        end

        def test_deserialize_value_object_empty
          input = <<XML
<?xml version="1.0"?>
<foo xmlns="urn:foo" />
XML

          reader = Reader.new
          reader.xml(input)
          reader.element_map = {
            '{urn:foo}foo' => lambda do |reader|
              return Deserializer.value_object(reader, TestVo, 'urn:foo')
            end
          }

          output = reader.parse

          vo = TestVo.new

          expected = {
            'name'       => '{urn:foo}foo',
            'value'      => vo,
            'attributes' => []
          }

          assert_instance_equal(
            expected,
            output
          )
        end
      end

      class TestVo
        attr_accessor :first_name
        attr_accessor :last_name
        attr_accessor :link

        def initialize
          @first_name = nil
          @last_name = nil
          @link = []
        end
      end
    end
  end
end
