# -*- coding: utf-8 -*-

module Dcmgr::Models
  class QueuedJob < BaseNew
    taggable 'job'

    many_to_one :parent_job, :key => :parent_id, :class => self
    one_to_many :children_jobs, :key => :parent_id, :class => self

    plugin :serialization
    serialize_attributes :yaml, :params
    serialize_attributes :yaml, :finish_message
    
    def validate

      # validations for null allowed columns
      case self.state
      when 'finished'
        if self.finish_status.nil?
          errors.add(:finish_status, 'finish_status is not set at finished state')
        end
        if self.finished_at.nil?
          errors.add(:finished_at, 'finished_at is not set at finished state')
        end
      when 'pending'
        if !self.worker_id.nil?
          errors.add(:worker_id, 'worker_id must be unset during pending state')
        end
      when 'running'
        if self.worker_id.nil?
          errors.add(:worker_id, 'worker_id must be set during running state')
        end
      end
    end

    def to_hash
      super.merge({:params => self.params, :finish_message=>self.finish_message})
    end

    # Insert new job entry to a queue.
    #
    # :retry_max
    #    (default 0 = try default retry count set to each queue worker.)
    def self.submit(queue_name, resource_uuid, params, opts=nil)
      opts = {:retry_max=>0}.merge(opts || {})
      
      db.transaction do
        job = create(:queue_name=>queue_name,
                     :state=>'pending',
                     :resource_id=>resource_uuid,
                     :retry_max => opts[:retry_max],
                     :params => params,
                     )
        job
      end
    end

    def self.pop(queue_name, worker_id, opts={})
      db.transaction do
        # Fetch the last item.
        job = self.dataset.filter(:queue_name=>queue_name,
                                  :state => 'pending',
                                  :worker_id=>nil,
                                  ).order(Sequel.asc(:id)).for_update.first
        if !job.nil?
          job.set({:worker_id=>worker_id, :state=>'running'})
          if job.started_at.nil?
            job.started_at=Time.now.utc
            if job.retry_max == 0 && opts[:retry_max_if_zero].to_i > 0
              # Set default retry max value per queue.
              job.retry_max = opts[:retry_max_if_zero].to_i
            end
          end
          
          # increment at begging of the job.
          job.retry_count += 1
          job.save_changes
        end
        job
      end
    end

    def self.cancel(job_uuid)
      db.transaction do
        job = self[job_uuid]
        raise "Unknown Job: #{job_uuid}" if job.nil?
        job.finish_cancel
        job
      end
    end

    # typecast and structure hash data for finish_message column.
    def finish_message=(msg)
      msg = case msg
            when Exception
              {:message=>msg.message, :error_type=>msg.class.to_s}
            when Hash, Array
              msg
            else
              {:message=>msg.to_s}
            end
      super(msg)
    end

    def finished?()
      self.state == 'finished'
    end

    def finish_cancel
      raise "Already terminated" if finished?
      finish_entry('cancel')
      self.save_changes
    end

    # Notify that the job is finished successfully.
    def finish_success(finish_message=nil)
      raise "Already terminated" if finished?
      finish_entry('success')
      if finish_message
        self.finish_message = finish_message
      end
      self.save_changes
    end
    
    # Notify that the job is finished successfully.
    def finish_fail(failure_reason)
      raise "Already terminated" if finished?

      if self.retry_max > self.retry_count
        # Push back the job state to be stored in the queue.
        self.state = 'pending'
        self.worker_id = nil
      else
        finish_entry('fail')
      end
      self.finish_message = failure_reason
      self.save_changes
    end

    private
    # set common fields at finish state. 
    def finish_entry(finish_status)
      self.state = 'finished'
      self.finished_at = Time.now.utc
      self.finish_status = finish_status
    end
  end
end
