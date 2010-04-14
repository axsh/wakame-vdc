
require 'sequel/model'

module Wakame
  module Models
    class ServiceClusterPool < Sequel::Model
      plugin :schema
      
      set_schema {
        primary_key :id, :type => Integer
        varchar :service_cluster_id
      }
      
      
      def self.register_cluster(name)
        id = Service::ServiceCluster.id(name)
        
        self.find_or_create(:service_cluster_id=>id)
      end
      
      def self.unregister_cluster(name)
        id = Service::ServiceCluster.id(name)
        self.delete(:service_cluster_id=>id)
      end
      
      def self.each_cluster(&blk)
        self.all.each { |m|
          cluster = Service::ServiceCluster.find(m.service_cluster_id)
          blk.call(cluster)
        }
      end
    end
  end

  Initializer.loaded_classes << Models::ServiceClusterPool
end
