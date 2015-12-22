module Tilia
  module Xml
    # This is the XML element interface.
    #
    # Elements are responsible for serializing and deserializing part of an XML
    # document into PHP values.
    #
    # It combines XmlSerializable and XmlDeserializable into one logical class
    # that does both.
    module Element
      include XmlSerializable
      include XmlDeserializable

      require 'tilia/xml/element/base'
      require 'tilia/xml/element/cdata'
      require 'tilia/xml/element/elements'
      require 'tilia/xml/element/key_value'
      require 'tilia/xml/element/uri'
      require 'tilia/xml/element/xml_fragment'
    end
  end
end
