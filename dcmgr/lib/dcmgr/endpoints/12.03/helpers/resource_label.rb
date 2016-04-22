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
      #
      # labels_param_each_pair(params['labels']) do |n, v|
      #   puts "name=#{n} value=#{v}"
      # end
      #
      # Accepted patterns for labels parameter:
      # 1. labels[][name]=xxxx&labels[][value]=yyyy
      # 2. labels[1][name]=xxxx&labels[1][value]=yyyy&labels[2][name]=xxxx&labels[2][value]=yyyy
      # 3. labels[xxxx]=yyyy&labels[nnnn]=mmmm
      def labels_param_each_pair(label_params, &blk)
        case label_params
        when Hash
          labels_params.each { |k, v|
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
          label_params.each_with_index { |l, idx|
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

      desc "Shows the labels assigned to a resource."
      param_uuid
      param :name, :String, desc: "show only the labels whose name start with pattern."
      get do
        ds = @uuid_resource.resource_labels_dataset

        ds = ds.grep(:name, "#{params[:name]}%") if params[:name]

        respond_with(R::ResourceLabelCollection.new(ds).generate)
      end

      desc "Shows a single label assigned to a resource"
      param_uuid
      param :name, :String, desc: "Show only the label with exactly this name."
      get '/:name' do
        l = @uuid_resource.label(params['name']) || raise(E::UnknownResourceLabel, params['id'], params['name'])
        respond_with(R::ResourceLabel.new(l).generate)
      end

      def self.single_label_set_params
        desc "Assigns a single label to a resource."
        param_uuid
        param :name, :String, required: true, desc: "The name to of this label."
        param :value, :String, required: true, desc: "The value to of this label."
      end

      single_label_set_params
      post '/:name' do
        single_label_set
      end

      single_label_set_params
      put '/:name' do
        single_label_set
      end

      def self.bulk_label_set_params
        desc "Assigns multiple labels to a resource."
        param_uuid
        param :name, :Array, required: true,
                     desc: "An array containing the names of the labels to assign."
        param :value, :Array, required: true,
                     desc: "An array containing the values of the labels to assign."
      end

      bulk_label_set_params
      post do
        bulk_label_set
      end

      bulk_label_set_params
      put do
        bulk_label_set
      end

      desc "Delete a single label from a resource."
      param_uuid
      param :name, :String, required: true,
                   desc: "The name of the label to delete."
      delete '/:name' do
        @uuid_resource.unset_label(params[:name])
        respond_with @uuid_resource.canonical_uuid
      end

      desc "Delete all labels from a resource."
      param_uuid
      delete do
        @uuid_resource.resource_labels.each { |l| l.destroy }
        respond_with @uuid_resource.canonical_uuid
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
        # name[]=n1&value[]=v1&name[]=n2&value[]=v2
        raise E::InvalidParameter, "'name' and 'value' arrays must be of the same size.'" unless params['name'].size == params['value'].size

        params['name'].size.times { |idx|
          blk.call(params['name'][idx], params['value'][idx])
        }
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



