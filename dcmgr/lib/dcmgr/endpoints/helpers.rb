
module Dcmgr
  module Endpoints
    module Helpers

      module ClassMethods
        def load_namespace(ns, bind)
          #load File.expand_path("../#{ns}.rb", __FILE__)
          # workaround for Rubinius
          p fname = File.expand_path("../#{ns}.rb", __FILE__)
          eval(File.read(fname), bind, fname)
        end
      end

      def self.included(klass)
        klass.extend ClassMethods
      end
    end
  end
end
