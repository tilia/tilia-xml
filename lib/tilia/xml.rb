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
    require 'tilia/xml/element'
    require 'tilia/xml/parse_exception'
    require 'tilia/xml/lib_xml_exception'
    require 'tilia/xml/reader'
    require 'tilia/xml/service'
    require 'tilia/xml/version'
    require 'tilia/xml/writer'
  end
end
