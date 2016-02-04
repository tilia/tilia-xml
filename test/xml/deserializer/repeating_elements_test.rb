require 'test_helper'

module Tilia
  module Xml
    module Deserializer
      class RepeatingElementsTest < Minitest::Test
        def test_read
          service = Service.new
          service.element_map['{urn:test}collection'] = lambda do |reader|
            return Deserializer.repeating_elements(reader, '{urn:test}item')
          end

          xml = <<XML
<?xml version="1.0"?>
<collection xmlns="urn:test">
    <item>foo</item>
    <item>bar</item>
</collection>
XML

          result = service.parse(xml)

          expected = [
            'foo',
            'bar',
          ]

          assert_equal(expected, result)
        end
      end
    end
  end
end
