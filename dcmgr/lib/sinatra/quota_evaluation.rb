# -*- coding: utf-8 -*-

require 'sinatra/base'
require 'json'

module Sinatra
  # Evaluate VDC quota header from frontend and helper methods for
  # Sinatra.
  #
  # Frontend sends "X-VDC-Account-Quota" header with JSON document. The
  # dcmgr API evaluate the document if the request can go through or
  # reject. This plugin allows to insert evaluation routines into the Sinatra
  # condition using custom DSL syntax.
  #
  # Typical HTTP request becomes like below:
  # 
  # POST /xxxxx HTTP/1.1
  # X-VDC-Account-ID: a-shpoolxx
  # X-VDC-Account-Quota: ["security_groups.count": 5,
  #   "instances.quota_weight":10.0]
  #
  # The above request expects to be evaluated with the a-shpoolxx
  # user's resources. a-shpoolxx is allowed to have 5 security groups
  # and 10.0 instances.
  #
  # # Basic usage of this extension.
  # Sinatra::QuotaEvaluation.evaluators do
  #   quota_key 'security_group.count' do
  #     # quota_value == 5
  #     quota_value <= Models::SecurityGroup.count
  #   end
  # end
  #
  # class App < Sinatra::Base
  #   register Sinatra::QuotaEvaluation
  #
  #   quota 'security_group.count'
  #   post '/aaaa/bbbb' do
  #     puts "total security group count is less than or equal to 5."
  #   end
  #
  #   quota 'security_group.xxxxx'
  #   put '/aaaa/bbbb' do
  #   end
  # end
  #
  # # Also works with Sinatra::Namespace extension.
  # class App < Sinatra::Base
  #   register Sinatra::Namespace
  #   # must be registered later on Namespace.
  #   register Sinatra::QuotaEvaluation
  #
  #   namespace '/security groups' do
  #     quota 'security_groups.count'
  #     post do
  #       puts "create security group"
  #     end
  #   end
  # end
  # 
  module QuotaEvaluation
    class << self

      class DSL
        attr_reader :tuples

        def self.parse(&blk)
          self.new.tap { |i| i.instance_eval(&blk) }
        end
        
        def initialize
          @tuples = {}
        end
        
        def quota_key(key, &blk)
          raise ArgumentError, "#{key} was set previously." if @tuples[key]
          @tuples[key] = [blk]
        end
      end

      def quota_defs
        @quota_defs ||= {}
      end

      def evaluators(&blk)
        dsl = DSL.parse(&blk)
        self.quota_defs.merge!(dsl.tuples)
      end
    end

    module ClassMethods
      # Set sinatra condition for this quota key to the endpoint.
      def quota(*quota_keys)
        quota_keys.each { |quota_key|
          tuple = QuotaEvaluation.quota_defs[quota_key]
          raise ArgumentError, "#{quota_key} is unknown quota key" unless tuple
        }
        
        return self if Dcmgr.conf.skip_quota_evaluation

        self.condition {
          # Skip quota evaluation if the quota document is not
          # avaialble.
          # For example, missing X-VDC-Account-Quota header or empty
          # JSON document. Missing X-VDC-Account-ID header also
          # results in skipping evaluation.
          return true if @quota_request.nil? || @quota_request.empty?
          
          quota_keys.each { |quota_key|
            next unless @quota_request.has_key?(quota_key)
            
            tuple = QuotaEvaluation.quota_defs[quota_key]
            begin
              @current_quota_key = quota_key
              if self.instance_eval &tuple[0]
                # common error for invalid result of quota
                # evaluation. it is recommended to raise an error
                # with nice message from the block.
                halt 400, "Exceeds quota limitation: #{request.request_method} #{request.path_info}"
              end
            ensure
              @current_quota_key = nil
            end
          }
          true
        }
        
        self
      end
    end

    module HelperMethods
      def quota_key
        @current_quota_key
      end

      def quota_value(key=self.quota_key)
        # set in before filter.
        @quota_request[key]
      end
    end
    
    module NamespacedMethods
      include ClassMethods
    end

    def self.registered(app)
      app.extend ClassMethods
      app.helpers HelperMethods

      # Parse quota request from the frontend.
      app.before do
        @quota_request = {}
        quota_json = request.env['HTTP_X_VDC_ACCOUNT_QUOTA']
        # Account quota is the specific values for the account set
        # by X-VDC-Account-ID. The JSON document in
        # X-VDC-Account-Quota should be ignored if the
        # X-VDC-Account-ID header did not come along with. 
        if quota_json && request.env.has_key?('HTTP_X_VDC_ACCOUNT_UUID')
          # JSON parse error is expected to raise error and halts
          # further request processing.
          @quota_request = ::JSON.parse(quota_json)
        end
      end

      # special care for Sinatra::Namespace
      if app.extensions.map{|c| c.to_s }.member?('Sinatra::Namespace')
        Sinatra::Namespace::NamespacedMethods.class_eval {
          include Sinatra::QuotaEvaluation::NamespacedMethods
        }
      end
    end
  end
end
