require 'test_helper'

module Tilia
  module Xml
    module Serializer
      class EnumTest < Minitest::Test
        def test_serialize
          service = Service.new
          service.namespace_map['urn:test'] = nil

          xml = service.write(
            '{urn:test}root',
            lambda do |writer|
              Serializer.enum(
                writer,
                [
                  '{urn:test}foo1',
                  '{urn:test}foo2',
                ]
              )
            end
          )

          expected = <<XML
<?xml version="1.0"?>
<root xmlns="urn:test">
   <foo1/>
   <foo2/>
</root>
XML
          assert_xml_equal(expected, xml)
        end
      end
    end
  end
end
