require 'active_support/concern'
require 'playful/lang/hash'
require 'playful/lang/array'
require 'playful/lang/boolean'
require 'playful/metadata/scanner'
require 'playful/file/scanner'
require 'playful/path_resolver'

# Additions to built-in classes
class Hash
  include Playful::Lang::Hash
end

class Array
  include Playful::Lang::Array
end

class TrueClass; include Boolean; end
class FalseClass; include Boolean; end

# app specific configuration
Playful::Application.config.app_config = {}
begin
  Property.where(:category => 'configuration').each do |p|
    Playful::Application.config.app_config[p.name.to_sym] = p.value
  end
rescue => e
  Rails.logger.warn("Playful failed to initialize app configuration: " + e.message)
end

# factory pattern for library code
module Playful::Factory
  def self.metadata_scanner
    options = {
        :tmdb_api_key => Playful::Application.config.app_config[:tmdb_api_key]
    }
    Playful::Metadata::Scanner.new(options)
  end

  def self.file_scanner
    Playful::File::Scanner.new(
        Playful::File::Driver::FileDriver.new(:path => Playful::Application.config.app_config[:file_exec_path]),
        Playful::File::Driver::FfmpegDriver.new(:path => Playful::Application.config.app_config[:ffmpeg_exec_path]),
        Playful::File::Driver::TagDriver.new
    )
  end

end

# hack for AMS until version 0.10 is here. point here is resolution for the correct
module ActiveModel
  class Serializer
    def self.serializer_for(resource)
      if resource.respond_to?(:to_ary)
        if Object.constants.include?(:ArraySerializer)
          ::ArraySerializer
        else
          ArraySerializer
        end
      else
        get_serializer_for(resource.class)
      end
    end

    def self.get_serializer_for(klass)
      serializer_class_name = "#{klass.name}Serializer"

      serializer_class =
      if RUBY_VERSION >= '2.0'
        begin
          Object.const_get serializer_class_name
        rescue NameError
          nil
        end
      else
        serializer_class_name.safe_constantize
      end

      if serializer_class
        serializer_class
      elsif klass.superclass
        get_serializer_for(klass.superclass)
      end
    end
  end
end


