class UserApiController < ApiController
  def index
    ds = User.dataset.with_deleted

    if params[:id]
      uuid = params[:id].split("u-")[1]
      uuid = params[:id] if uuid.nil?
      ds = ds.filter(:uuid.like("#{uuid}%"))
    end

    if params[:account_id]
      ds = ds.filter(:primary_account_id =>params[:account_id])
    end

    if params[:login_id]
      ds = ds.filter(:login_id =>params[:login_id])
    end

    if params[:name]
      ds = ds.filter(:name =>params[:name])
    end

    if params[:locale]
      ds = ds.filter(:locale =>params[:locale])
    end

    if params[:enabled]
      ds = ds.filter(:locale =>params[:locale])
    end

    if params[:time_zone]
      ds = ds.filter(:time_zone =>params[:time_zone])
    end

    datetime_range_params_filter(:created, ds)
    datetime_range_params_filter(:deleted, ds)
    datetime_range_params_filter(:last_login, ds)

    collection_respond_with(ds)
  end

  def show
    ds = find_by_uuid(:User, params[:id])
    raise "UnknownInstance"if ds.nil?
    respond_with(generate(ds), :to=>[:json])
  end
end
