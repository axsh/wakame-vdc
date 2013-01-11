# -*- coding: utf-8 -*-

module Dcmgr::Models
  class QueuedJob < BaseNew
    taggable 'job'

    many_to_one :parent_job, :key => :parent_id, :class => self
    one_to_many :children_jobs, :key => :parent_id, :class => self
    
    def validate
    end

    # Insert new job entry to a queue.
    #
    def self.submit(queue_name, resource_uuid, parent_id=nil)
      create(:queue_name=>queue_name,
             :state=>'pending',
             :resource_id=>resource_uuid,
             )
    end

    def self.pop(queue_name, worker_id)
      db.transaction do
        # Fetch the last item.
        j = self.dataset.for_update.filter(:queue_name=>queue_name,
                                           :worker_id=>nil,
                                           :state => 'pending',
                                           ).order(Sequel.asc(:id)).first
        if !j.nil?
          j.update(:worker_id=>worker_id,
                   :state=>'running',
                   :started_at=>Time.now.utc)
        end
        j
      end
    end

    def self.cancel(job_uuid)
      self.find(job_uuid).cancel
    end

    def finished?()
      self.state == 'finished'
    end

    def cancel
      raise "Already terminated" if finished?
      self.state = 'finished'
      self.finish_status = 'cancel'
      self.save_changes
    end

    # Notify that the job is finished successfully.
    def finish_success()
      raise "Already terminated" if finished?
      self.state = 'finished'
      self.finish_status = 'success'
      self.save_changes
    end
    
    # Notify that the job is finished successfully.
    def finish_failure(failure_reason)
      raise "Already terminated" if finished?
      
      if j.retry_max < j.retry_count
        # Push back the job state to be stored in the queue. But
        # retry_count is incremented.
        j.retry_count += 1
        j.state = 'pending'
        j.worker_id = nil
      else
        self.state = 'finished'
        self.finish_status = 'fail'
        self.failure_reason = failure_reason
      end
      self.save_changes
    end

    private
    def _delete_destory
    end
  end
end
