# encoding: utf-8

# Define common endpoints for resource label operations.

require 'sinatra/namespace'
require 'dcmgr/endpoints/12.03/responses/resource_label'

module Dcmgr::Endpoints::V1203::Helpers
  M = Dcmgr::Models
  E = Dcmgr::Endpoints::Errors
  R = Dcmgr::Endpoints::V1203::Responses


  # class App < Sinatra::Base
  #   register Sinatra::Namespace
  #
  #   namespace '/resource' do
  #     register V1203::Helpers::ResourceLabel
  #     enable_resource_label(M::Instance)
  #   end
  # end
  module ResourceLabel

    def self.registered(klass)
      unless klass.respond_to?(:namespace)
        raise TypeError, "#{klass} does not enable Sinatra::Namespace."
      end
      ns = klass.namespace('/:id/labels', &LABELS_ROUTES)
      ns.before do
        @uuid_resource = klass.instance_variable_get(:@labeled_model_class)[params['id']] || raise(E::UnknownUUIDError, params['id'])
      end
      klass.extend ClassMethods
      klass.helpers HelperMethods
    end

    module HelperMethods
      # 1. labels[][name]=xxxx&labels[][value]=yyyy
      # 2. labels[1][name]=xxxx&labels[1][value]=yyyy&labels[2][name]=xxxx&labels[2][value]=yyyy
      # 3. labels[xxxx]=yyyy&labels[nnnn]=mmmm
      def labels_param_each_pair(&blk)
        case params['labels']
        when Hash
          params['labels'].each { |k, v|
            if v.is_a?(Hash)
              # For pattern 2.
              if v['name'].blank?
                raise E::InvalidParameter, "blank name parameter from labels[#{k}]"
              elsif v['value'].blank?
                raise E::InvalidParameter, "blank value parameter from labels[#{k}]"
              else
                blk.call(v['name'], v['value'])
              end
            else
              # For pattern 3.
              if k.blank?
                raise E::InvalidParameter, "blank name parameter from labels"
              elsif v.blank?
                raise E::InvalidParameter, "blank value parameter from labels[#{k}]"
              else
                blk.call(k, v)
              end
            end
          }
        when Array
          # For pattern 1.
          params['labels'].each_with_index { |l, idx|
            if !l.is_a?(Hash)
              raise E::InvalidParameter, "labels[#{idx}] is not right type"
            elsif l['name'].blank?
              raise E::InvalidParameter, "blank name parameter from labels[#{idx}]"
            elsif l['value'].blank?
              raise E::InvalidParameter, "blank value parameter from labels[#{idx}]"
            end
            blk.call(l['name'], l['value'])
          }
        else
          raise E::InvalidParameter, "Invalid labels parameter"
        end
      end
    end

    LABELS_ROUTES = proc {
      get do
        ds = @uuid_resource.resource_labels_dataset
        
        if !params['name'].blank?
          ds = if params['name'] =~ /(.+)*$/
                 ds.grep(:name, "#{$1}%")
               else
                 ds.filter(:name=>params['name'])
               end
        end
        
        respond_with(R::ResourceLabelCollection.new(ds).generate)
      end
      
      get '/:name' do
        l = @uuid_resource.label(params['name']) || raise(E::UnknownResourceLabel, params['id'], params['name'])
        respond_with(R::ResourceLabel.new(l).generate)
      end
      
      post '/:name' do
        single_label_set
      end
      
      put '/:name' do
        single_label_set
      end
      
      post do
        bulk_label_set
      end

      put do
        bulk_label_set
      end
      
      # delete a label.
      delete '/:name' do
        @uuid_resource.unset_label(params[:name])
      end

      # clear all labels.
      delete do
        @uuid_resource.unset_label(params[:name])
      end

      private
      
      def single_label_set
        l = @uuid_resource.set_label(params['name'], params['value'])
        respond_with(R::ResourceLabel.new(l).generate)
      end

      def bulk_label_set
        results = []
        each_bulk_label_params do |n, v|
          results << @uuid_resource.set_label(n, v)
        end
        
        respond_with(results.map {|l| R::ResourceLabel.new(l).generate })
      end

      def each_bulk_label_params(&blk)
        if params['name'].is_a?(Array) && params['value'].is_a?(Array)
          # name[]=n1&value[]=v1&name[]=n2&value[]=v2
          raise E::InvalidParameter unless params['name'].size == params['value'].size
          params['name'].size.times { |idx|
            blk.call(params['name'][idx], params['value'][idx])
          }
        elsif params['label'].is_a?(Array)
          # label[][name]=xxx&label[][value]=yyy&label[][name]=xxx1&label[][value]=yyy1
          params['label'].each { |l|
            if !l['name'].blank? && l.has_key?('value')
              blk.call(l['name'], l['value'])
            else
              logger.warn("Invalid name & value pair: #{l.inspect}")
            end
          }
        else
          raise E::InvalidParameter, "Unknown input parameter"
        end
      end
    }

    module ClassMethods
      def enable_resource_label(mclass)
        unless mclass < M::BaseNew && mclass.plugins.member?(M::Plugins::ResourceLabel)
          raise ArgumentError, "Model class '#{mclass}' does not support resource label."
        end
        self.instance_variable_set(:@labeled_model_class, mclass)
      end
    end
  end
end



