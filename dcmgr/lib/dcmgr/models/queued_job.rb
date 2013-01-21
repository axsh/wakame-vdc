# -*- coding: utf-8 -*-

module Dcmgr::Models
  class QueuedJob < BaseNew
    taggable 'job'

    many_to_one :parent_job, :key => :parent_id, :class => self
    one_to_many :children_jobs, :key => :parent_id, :class => self

    plugin :serialization
    serialize_attributes :yaml, :params
    
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

    # Insert new job entry to a queue.
    #
    def self.submit(queue_name, resource_uuid, opts=nil)
      opts = {:retry_max=>1}.merge(opts || {})
      
      db.transaction do
        job = create(:queue_name=>queue_name,
                     :state=>'pending',
                     :resource_id=>resource_uuid,
                     :retry_max => opts[:retry_max],
                     )
        job
      end
    end

    def self.pop(queue_name, worker_id)
      db.transaction do
        # Fetch the last item.
        job = self.dataset.filter(:queue_name=>queue_name,
                                  :state => 'pending',
                                  :worker_id=>nil,
                                  ).order(Sequel.asc(:id)).for_update.first
        if !job.nil?
          update = {:worker_id=>worker_id, :state=>'running'}
          if job.started_at.nil?
            update[:started_at]=Time.now.utc
          end
          job.set(update)
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

    def finished?()
      self.state == 'finished'
    end

    def finish_cancel
      raise "Already terminated" if finished?
      finish_entry('cancel')
      self.save_changes
    end

    # Notify that the job is finished successfully.
    def finish_success()
      raise "Already terminated" if finished?
      finish_entry('success')
      self.save_changes
    end
    
    # Notify that the job is finished successfully.
    def finish_fail(failure_reason)
      raise "Already terminated" if finished?
      
      if self.retry_max < self.retry_count
        # Push back the job state to be stored in the queue. But
        # retry_count is incremented.
        self.retry_count += 1
        self.state = 'pending'
        self.worker_id = nil
      else
        finish_entry('fail')
        self.failure_reason = failure_reason
      end
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
