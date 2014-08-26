# -*- coding: utf-8 -*-

module Mussel
  class Instance < Base

    class << self
      def create(params)
        super(params)
      end

      def destroy(instance)
        super(instance.id)
      end
    end
  end

  module Responses
    class Instance < Base
    end
  end
end
