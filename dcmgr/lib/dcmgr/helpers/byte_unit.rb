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

    def byte_unit_convert(v, base_unit, get_unit)
      return v if v.to_i == 0

      ((base_unit.to_i <=> get_unit.to_i) == 0) ? v : v * (base_unit / get_unit.to_f)
    end
    module_function :byte_unit_convert

    def convert_byte(v, get_unit)
      byte_unit_convert(v, B, get_unit).to_i
    end
    module_function :convert_byte
  end
end
