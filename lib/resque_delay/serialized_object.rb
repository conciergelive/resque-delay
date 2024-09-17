# frozen_string_literal: true

module ResqueDelay
  class SerializedObject
    CLASS_STRING_FORMAT = /\ACLASS\:([A-Z][\w\:]+)\z/
    AR_STRING_FORMAT    = /\AAR\:([A-Z][\w\:]+)\:(\d+)\z/
    DM_STRING_FORMAT    = /\ADM\:((?:[A-Z][a-zA-z]+)(?:\:\:[A-Z][a-zA-z]+)*)\:([\d\:]+)\z/
    MG_STRING_FORMAT    = /\AMG\:([A-Z][\w\:]+)\:(\w+)\z/
    SYM_STRING_FORMAT   = /\ASYMBOL\:(.*)\z/
    OBJ_FORMAT          = /\AOBJ\:([a-zA-Z0-9+\/=]*)\z/

    attr_reader :obj

    def self.deserialize(str)
      new(str).deserialize
    end

    def self.serialize(obj)
      new(obj).serialize
    end

    def self.display_name(object_ref, method_name)
      case object_ref
      when CLASS_STRING_FORMAT
        "#{$1}.#{method_name}"
      when AR_STRING_FORMAT
        "#{$1}##{method_name}"
      when DM_STRING_FORMAT
        "#{$1}##{method_name}"
      when MG_STRING_FORMAT
        "#{$1}##{method_name}"
      when SYM_STRING_FORMAT
        "Symbol##{method_name}"
      else
        "Unknown##{method_name}"
      end
    end

    def initialize(obj)
      @obj = obj
    end

    def deserialize
      case obj
      when CLASS_STRING_FORMAT
        $1.constantize
      when AR_STRING_FORMAT
        $1.constantize.find($2)
      when DM_STRING_FORMAT
        $1.constantize.get!(*$2.split(':'))
      when MG_STRING_FORMAT
        $1.constantize.find($2)
      when SYM_STRING_FORMAT
        $1.to_sym
      when OBJ_FORMAT
        Marshal.load(Base64.strict_decode64($1))
      else
        obj
      end
    end

    def serialize
      if obj.kind_of?(Class) || obj.kind_of?(Module)
        "CLASS:#{obj.name}"
      elsif defined?(ActiveRecord) && obj.kind_of?(ActiveRecord::Base)
        "AR:#{obj.class}:#{obj.id}"
      elsif defined?(DataMapper) && obj.kind_of?(DataMapper::Resource)
        "DM:#{obj.class}:#{obj.key.join(':')}"
      elsif defined?(Mongoid) && obj.kind_of?(Mongoid::Document)
        "MG:#{obj.class}:#{obj.id}"
      elsif obj.is_a?(Symbol)
        "SYMBOL:#{obj}"
      elsif obj.is_a? String
        obj
      else
        "OBJ:#{Base64.strict_encode64(Marshal.dump(obj))}"
      end
    end
  end
end
