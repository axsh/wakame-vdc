class AccountApiController < ApiController
  def index
    ds = Account.dataset.with_deleted

    if params[:id]
      uuid = params[:id].split("a-")[1]
      uuid = params[:id] if uuid.nil?
      ds = ds.filter(:uuid.like("%#{uuid}%"))
    end

    if params[:name]
      ds = ds.filter(:name =>params[:name])
    end

    if params[:enabled]
      ds = ds.filter(:enabled =>params[:enabled])
    end

    datetime_range_params_filter(:created, ds)

    collection_respond_with(ds)
  end

  def show
    ds = find_by_uuid(:Account, params[:id])
    raise "UnknownAccount"if ds.nil?
    respond_with(ds, :to=>[:json])
  end
end
