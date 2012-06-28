# -*- coding: utf-8 -*-

require 'sinatra/base'
require 'json'

module Sinatra
  # Evaluate VDC quota header from frontend and helper methods for
  # Sinatra.
  #
  # Frontend sends "X-VDC-Account-Quota" header with JSON document. The
  # dcmgr API evaluate the document if the request can go through or
  # reject. This plugin allows to set evaluation routines into the Sinatra
  # before filter using custom DSL syntax.
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
  # class App < Sinatra::Base
  #   register Sinatra::QuotaEvaluation
  #
  #   quota 'security_groups.count' do
  #     post '/aaaa/bbbb' do
  #       # quota_value == 5
  #       quota_value <= Models::SecurityGroup.count
  #     end
  #   end
  #
  #   post '/aaaa/bbbb' do
  #     puts "total security group count is less than or equal to 5."
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
  #     quota 'security_groups.count' do
  #       post do
  #         # do evaluation
  #       end
  #     end
  #
  #     post do
  #       puts "create security group"
  #     end
  #   end
  # end
  # 
  module QuotaEvaluation
    module ClassMethods

      class DSL
        attr_reader :tuples

        def self.parse(&blk)
          self.new.tap { |i| i.instance_eval(&blk) }
        end
        
        def initialize
          @tuples = []
        end
        
        def post(pattern=nil, &blk)
          @tuples << ['POST', pattern, blk]
        end

        def put(pattern=nil, &blk)
          @tuples << ['PUT', pattern, blk]
        end
      end

      def quota_defs
        @quota_defs
      end
      
      # DSL for quota checking
      def quota(quota_key, &blk)
        dsl = DSL.parse(&blk)
        quota_defs[quota_key] = dsl.tuples

        return self if Dcmgr.conf.skip_quota_evaluation
        
        dsl.tuples.group_by {|i| i[1] }.each { |pattern, tls|
          checks = {}
          tls.each { |tuple|
            verb, pattern, b = tuple
            checks[verb] = b
          }
          self.before pattern do
            next true if @quota_request[quota_key].nil?

            begin
              @current_quota_key = quota_key
              chk_blk = checks[request.request_method]
              if chk_blk
                if self.instance_eval &chk_blk
                  # common error for invalid result of quota
                  # evaluation. it is recommended to raise an error
                  # with nice message from chk_blk.
                  halt 400, "Exceeds quota limitation: #{request.request_method} #{request.path_info}"
                end
              end
            ensure
              @current_quota_key = nil
            end
          end
        }
        self
      end
    end

    module HelperMethods
      def quota_key
        @current_quota_key
      end

      def quota_value(key=self.quota_key)
        @quota_request[key]
      end
    end

    
    module NamespacedMethods
      include ClassMethods

      def quota_defs
        base.instance_variable_get(:@quota_defs)
      end
    end

    def self.registered(app)
      app.extend ClassMethods
      app.class_eval {
        @quota_defs = {}
      }
      app.helpers HelperMethods

      # Parse quota request from the frontend.
      app.before do
        @quota_request = {}
        quota_json = request.env['HTTP_X_VDC_ACCOUNT_QUOTA']
        if quota_json
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
