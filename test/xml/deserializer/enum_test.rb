require 'test_helper'

module Tilia
  module Xml
    module Deserializer
      class EnumTest < Minitest::Test
        def test_deserialize
          service = Service.new
          service.element_map['{urn:test}root'] = Deserializer.method(:enum)

          xml = <<XML
<?xml version="1.0"?>
<root xmlns="urn:test">
   <foo1/>
   <foo2/>
</root>
XML

          result = service.parse(xml)

          expected = [
            '{urn:test}foo1',
            '{urn:test}foo2'
          ]

          assert_equal(expected, result)
        end

        def test_deserialize_default_namespace
          service = Service.new
          service.element_map['{urn:test}root'] = lambda do |reader|
            return Deserializer.enum(reader, 'urn:test')
          end

          xml = <<XML
<?xml version="1.0"?>
<root xmlns="urn:test">
   <foo1/>
   <foo2/>
</root>
XML

          result = service.parse(xml)

          expected = [
            'foo1',
            'foo2'
          ]

          assert_equal(expected, result)
        end
      end
    end
  end
end
