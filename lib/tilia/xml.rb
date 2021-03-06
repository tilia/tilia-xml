# Namespace for Tilia library
module Tilia
  # Load active support core extensions
  require 'active_support'
  require 'active_support/core_ext'

  # Tilia libraries
  require 'tilia/uri'

  # Namespace of the Tilia::Xml library
  module Xml
    require 'tilia/xml/xml_deserializable'
    require 'tilia/xml/xml_serializable'
    require 'tilia/xml/context_stack_trait'
    require 'tilia/xml/deserializer'
    require 'tilia/xml/element'
    require 'tilia/xml/parse_exception'
    require 'tilia/xml/lib_xml_exception'
    require 'tilia/xml/reader'
    require 'tilia/xml/serializer'
    require 'tilia/xml/service'
    require 'tilia/xml/version'
    require 'tilia/xml/writer'
  end

  # Container to avoid pass-by-reference quirks
  class Box
    attr_accessor :value

    def initialize(v = nil)
      @value = v
    end
  end
end
