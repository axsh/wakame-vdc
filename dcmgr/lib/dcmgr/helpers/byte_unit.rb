# -*- coding: utf-8 -*-

module Dcmgr::Helpers
  module ByteUnit
    B = BYTE = 1
    KB = KILOBYTE = 1024
    MB = MEGABYTE = KILOBYTE * 1024
    GB = GIGABYTE = MEGABYTE * 1024
    TB = TERABYTE = GIGABYTE * 1024
    PB = PETABYTE = TERABYTE * 1024
    EB = EXABYTE  = PETABYTE * 1024
    ZB = ZETTABYTE  = EXABYTE * 1024
    YB = YOTTABYTE  = ZETTABYTE * 1024

    UNIT_PATTERNS={
      'B'  => BYTE,
      'K'  => KILOBYTE,
      'KB' => KILOBYTE,
      'M'  => MEGABYTE,
      'MB' => MEGABYTE,
      'G'  => GIGABYTE,
      'GB' => GIGABYTE,
      'T'  => TERABYTE,
      'TB' => TERABYTE,
      'P'  => PETABYTE,
      'PB' => PETABYTE,
      'E'  => EXABYTE,
      'EB' => EXABYTE,
      'Z'  => ZETTABYTE,
      'ZB' => ZETTABYTE,
      'Y'  => YOTTABYTE,
      'YB' => YOTTABYTE,
    }.freeze

    UNIT_SUFFIX=UNIT_PATTERNS.select{|k,v| k.size == 1 }.invert.freeze

    # 30MB in Byte
    #   byte_unit_convert(30, ByteUnit::KB, ByteUnit::B)
    # 30MB in KB
    #   byte_unit_convert(30, ByteUnit::MB, ByteUnit::KB)
    def byte_unit_convert(v, base_unit, get_unit)
      return v if v.to_i == 0

      ((base_unit.to_i <=> get_unit.to_i) == 0) ? v : v * (base_unit / get_unit.to_f)
    end
    module_function :byte_unit_convert

    # Convert numeric byte size to given byte unit.
    def convert_byte(v, get_unit)
      byte_unit_convert(v, B, get_unit).to_i
    end
    module_function :convert_byte

    # Convert arbitrary representation (number or string) of byte size
    # to the given byte unit.
    #   convert_to(1024, KB) => 1.0
    #   convert_to("1024kb", MB) => 1.0
    def convert_to(v, to_unit)
      from_unit = B
      case v
      when String
        if v.upcase =~ /([\d+-\.]+)\s*(#{UNIT_PATTERNS.keys.join('|')})?/
          v = $1.to_f
          if $2
            from_unit = UNIT_PATTERNS[$2]
          end
        else
          raise ArgumentError, "Invalid string representaion"
        end
      when Numeric
      else
        raise ArgumentError, "v must be String or Numeric"
      end

      byte_unit_convert(v, from_unit, to_unit)
    end
    module_function :convert_to

    def convert_to_string(v, to_unit, round=nil)
      # TODO: more adaptive default round size
      # round = to_unit / from_unit? 0 : 2
      round ||= 0
      v = convert_to(v, to_unit).round(round)

      "#{v}#{UNIT_SUFFIX[to_unit]}"
    end
    module_function :convert_to_string
  end
end
