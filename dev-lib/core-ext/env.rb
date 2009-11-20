#!/usr/bin/ruby
# encoding: utf-8

require 'rbconfig'

class << ENV
  
  # fetch an environmental variable value and
  # parse it according to type:
  #   - array    - numeric
  #   - string   - boolean
  def read(var, as_type = String, *arguments)
    value = fetch(var.to_s) { return(nil) }
    return(parse(value, as_type, *arguments))
  end
  
  def add_onto( var, *values )
    values = [values, ENV[ var.to_s ]].flatten!
    values.compact!
    ENV[ var.to_s ] = values.join( path_separator )
  end
  
  def push_onto( var, *values )
    values = [ENV[ var.to_s ], values].flatten!
    values.compact!
    ENV[ var.to_s ] = values.join( path_separator )
  end
  
  def path_separator
    Config::CONFIG[ 'PATH_SEPARATOR' ] or ':'
  end
  
  private
  def parse(value, type, *args)
    result = case type.to_s.downcase
    when 'array', 'list' then parse_array(value, *args)
    when 'string' then parse_string(value, *args)
    when 'float' then parse_float(value, *args)
    when 'boolean' then parse_boolean(value, *args)
    when 'number', 'numeric'
      value =~ /\./ ? parse_float(value, *args) : parse_int(value, *args)
    else
      warn(
        ("ENV#parse (%s:%i): do not know how to parse to %p " \
        "-- returning original string value") % [__FILE__, __LINE__, type]
      )
      value
    end
    value.tainted? and result.taint
    return result
  end

  def parse_array(value, separator = Config::CONFIG['PATH_SEPARATOR'], sub_type = String, *args)
    out = value.split(separator).map! do |item|
      value.tainted? and item.taint
      parse(item, sub_type, *args)
    end
    return out
  end

  def parse_int(value, base = 10)
    value.to_i(base)
  end

  def parse_float(value)
    value.to_f
  end

  def parse_string(value)
    value.nil? || value.empty? and return(nil)
    value =~ /^(false|0+|no|off|nil)$/i and return(nil)
    return(value)
  end

  def parse_boolean(value)
    value.nil? || value.empty? and return(nil)
    value =~ /^(false|0+|no|f)$/i ? false : true
  end

end
