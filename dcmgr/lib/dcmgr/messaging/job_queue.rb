# -*- coding: utf-8 -*-

module Dcmgr
  module Messaging
    
    def self.job_queue
      JobQueue.new_backend
    end

    #
    # Dcmgr::Messaging::JobQueue.backend(:Sequel)
    # Dcmgr::Messaging::JobQueue.backend(:AMQPClient, @node)
    # Dcmgr::Messaging.job_queue.submit('q1', xxx)
    # 
    class JobQueue
      def self.backend(klass, *args)
        klass = self.const_get(klass) if klass.is_a?(Symbol)
        raise ArgumentError unless klass < self
        @backend_class = klass
        @new_args = args
      end

      def self.new_backend
        @backend_class || raise("Undefined JobQueue backend class")
        @backend_class.new(*@new_args)
      end
      
      def submit(queue_name, resource_uuid, opts={}); end
      def pop(queue_name, worker_id, opts={}); end
      def cancel(job_id); end
      def finish_success(job_id); end
      def finish_fail(job_id, failure_reason); end
      
      class Sequel < self
        def submit(queue_name, resource_uuid, opts={})
          opts = {:parent_id=>nil}.merge(opts)
          Models::QueuedJob.submit(queue_name, resource_uuid, opts[:parent_id]).to_hash
        end

        def pop(queue_name, worker_id, opts={})
          opts = {}.merge(opts)
          Models::QueuedJob.pop(queue_name, worker_id).to_hash
        end

        def cancel(job_id)
          Models::QueuedJob.cancel(job_id).to_hash
        end

        def finish_success(job_id)
          job = Models::QueuedJob[job_id]
          raise "Unknown Job: #{job_id}" if job.nil?
          job.finish_success
          job.to_hash
        end

        def finish_fail(job_id, failure_reason)
          job = Models::QueuedJob[job_id]
          raise "Unknown Job: #{job_id}" if job.nil?
          job.finish_fail(failure_reason)
          job.to_hash
        end
      end

      class AMQPClient < self
        def initialize(node)
          raise ArgumentError if !node.is_a?(Isono::Node)
          @node = node
        end
        
        def submit(queue_name, resource_uuid, opts={})
          rpc.request('jobqueue-proxy', 'submit',
                      queue_name, resource_uuid, opts)
        end

        def pop(queue_name, worker_id, opts={})
          opts = {}.merge(opts)
          rpc.request('jobqueue-proxy', 'pop',
                      queue_name, worker_id)
        end

        def cancel(job_id)
          rpc.request('jobqueue-proxy', 'cancel',
                      job_id)
        end

        def finish_success(job_id)
          rpc.request('jobqueue-proxy', 'finish_success',
                      job_id)
        end

        def finish_fail(job_id, failure_reason)
          rpc.request('jobqueue-proxy', 'finish_fail',
                      job_id, failure_reason)
        end

        private
        def rpc
          Isono::NodeModules::RpcChannel.new(@node)
        end
      end
    end
  end
end
