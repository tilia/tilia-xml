require 'test_helper'

module Tilia
  module Xml
    module Serializer
      class RepeatingElementsTest < Minitest::Test
        def test_serialize
          service = Service.new
          service.namespace_map['urn:test'] = nil
          xml = service.write(
            '{urn:test}collection',
            lambda do |writer|
              Serializer.repeating_elements(
                writer,
                [
                  'foo',
                  'bar'
                ],
                '{urn:test}item'
              )
            end
          )

          expected = <<XML
<?xml version="1.0"?>
<collection xmlns="urn:test">
   <item>foo</item>
   <item>bar</item>
</collection>
XML

          assert_xml_equal(expected, xml)
        end
      end
    end
  end
end
