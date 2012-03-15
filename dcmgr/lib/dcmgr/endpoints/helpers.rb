
module Dcmgr
  module Endpoints
    module Helpers

      module ClassMethods
        def load_namespace(ns)
          fname = File.expand_path("#{ns}.rb", File.dirname(caller.first.split(':').first))
          #::Kernel.load fname
          # workaround for Rubinius
          class_eval(File.read(fname), fname)
        end
      end

      def self.included(klass)
        klass.extend ClassMethods
      end
    end
  end
end
