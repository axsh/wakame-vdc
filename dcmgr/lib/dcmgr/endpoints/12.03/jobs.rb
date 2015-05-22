# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/queued_job'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/jobs' do
  get do
    # description 'Show lists of the volume_snapshots'
    # params start, fixnum, optional
    # params limit, fixnum, optional
    ds = M::QueuedJob.dataset

    ds = datetime_range_params_filter(:created, ds)
    ds = datetime_range_params_filter(:deleted, ds)

    if params[:state]
      ds = ds.filter(:state=>params[:state])
    end

    collection_respond_with(ds) do |paging_ds|
      R::QueuedJobCollection.new(paging_ds).generate
    end
  end

  get '/:id' do
    job = find_by_uuid(:QueuedJob, params[:id])
    raise E::UnknownJob, params[:id] if job.nil?
    respond_with(R::QueuedJob.new(job).generate)
  end

  # cancel running job
  delete '/:id' do
    job = find_by_uuid(:QueuedJob, params[:id])

    job.cancel

    respond_with([job.canonical_uuid])
  end
end
