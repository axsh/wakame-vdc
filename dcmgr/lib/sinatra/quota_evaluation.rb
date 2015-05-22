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
  #   quota_type 'instance.count' do
  #     fetch do
  #       Models::Instance.dataset.count.to_i
  #     end
  #
  #     evaluate do |fetch_value|
  #       quota_value <= fetch_value
  #     end
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

        def quota_type(key, &blk)
          raise ArgumentError, "#{key} was set already." if @tuples[key]
          @tuples[key] = QuotaType.parse(&blk)
        end
        alias :quota_key :quota_type

        # DSL for quota_type section
        class QuotaType

          def self.parse(&blk)
            self.new.parse(&blk)
          end

          def initialize()
            @fetch_block=nil
            @evaluate_block=nil
          end

          def parse(&blk)
            instance_eval(&blk)
            raise "Need to set fetch and evaluate blocks" if @fetch_block.nil? || @evaluate_block.nil?
            [@fetch_block, @evaluate_block]
          end

          def fetch(&blk)
            @fetch_block = blk
          end

          def evaluate(&blk)
            if !(1..2).include?(blk.arity)
              raise ArgumentError, "Block can have one or two arguments to pass."
            end
            @evaluate_block = blk
          end
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
      class EndpointCondition
        attr_reader :request_amount_block

        def initialize
          # return 0 as default for *.count quota keys.
          @request_amount_block = lambda { 0 }
        end

        def self.parse(&blk)
          new_obj = self.new

          DSL.new(new_obj).instance_eval(&blk)

          new_obj
        end

        class DSL
          def initialize(subject)
            @subject = subject
          end

          def request_amount(&blk)
            @subject.instance_variable_set(:@request_amount_block, blk)
          end
        end
      end

      # Set sinatra condition for this quota key to the endpoint.
      # quota('xxx.count')
      # quota('yyy.count') do
      #   request_amount do
      #     # Here runs in Sinatra context.
      #     params[:count].to_i
      #   end
      # end
      # get '/endpoint1' do
      # end
      def quota(quota_key, &blk)
        tuple = QuotaEvaluation.quota_defs[quota_key]
        raise ArgumentError, "#{quota_key} is unknown quota key. (Defined at around #{caller[3]})" unless tuple

        return self if Dcmgr::Configurations.dcmgr.skip_quota_evaluation

        condparam = blk ? EndpointCondition.parse(&blk) : EndpointCondition.new

        self.condition {
          # Skip quota evaluation if the quota document is not
          # avaialble.
          # For example, missing X-VDC-Account-Quota header or empty
          # JSON document. Missing X-VDC-Account-ID header also
          # results in skipping evaluation.
          return true unless @quota_request.is_a?(Hash) && @quota_request.has_key?(quota_key)

          begin
            @current_quota_type = quota_key

            if self.instance_exec(self.instance_exec(&tuple[0]),
                                  self.instance_exec(&condparam.request_amount_block),
                                  &tuple[1])
              raise Dcmgr::Endpoints::Errors::ExceedQuotaLimit, "Exceeds quota limitation: #{request.request_method} #{request.path_info} #{@current_quota_type}"
            end
          ensure
            @current_quota_type = nil
          end

          true
        }

        self
      end
    end

    module HelperMethods
      def quota_type
        @current_quota_type
      end
      alias :quota_key :quota_type

      def quota_value(key=self.quota_type)
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
