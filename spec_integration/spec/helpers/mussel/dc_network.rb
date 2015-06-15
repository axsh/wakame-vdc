# -*- coding: utf-8 -*-

module Mussel
  class DcNetwork < Base
    def self.create(params)
      super(params)
    end

    def self.add_offering_modes(uuid, params)
      JSON.parse(`#{parse_params(params)} #{MUSSEL} #{class_name} add_offering_modes #{uuid}`)
    end
  end

  module Responses
    class DcNetwork < Base
    end
  end
end
