class ApiController < ApplicationController
  layout false
  respond_to :json
  skip_before_filter :login_required

  def find_by_uuid(model_class, uuid)
    if model_class.is_a?(Symbol)
      model_class = Sequel::Model.const_get(model_class, false)
    end
    raise "Invalid UUID Syntax: #{uuid}" if !model_class.valid_uuid_syntax?(uuid)
    item = model_class[uuid] || raise("Unknown UUID Resource #{uuid.to_s}")
  end

  def datetime_range_params_filter(param, ds)
    since_time = until_time = nil
    since_key = "#{param}_since"
    until_key = "#{param}_until"
    if params[since_key]
      since_time = to_utc(params[since_key])
    end

    if params[until_key]
      until_time = to_utc(params[until_key])
    end

    ds = if since_time && until_time
           if !(since_time < until_time)
             raise("Invalid Parameter #{since_key} is larger than #{until_key}")
           end
           ds.filter("#{param}_at >= ?", since_time).filter("#{param}_at <= ?", until_time)
         elsif since_time
           ds.filter("#{param}_at >= ?", since_time)
         elsif until_time
           ds.filter("#{param}_at <= ?", until_time)
         else
           ds
         end
    ds
  end

  def paging_params_filter(ds)
    total = ds.count

    start = if params[:start]
              if params[:start] =~ /^\d+$/
                params[:start].to_i
              else
                raise("Invalid Parameter :start")
              end
            else
              0
            end
    limit = if params[:limit]
              if params[:limit] =~ /^\d+$/
                params[:limit].to_i
              else
                raise("Invalid Parameter :limit")
              end
            else
              0
            end
    limit = limit < 1 ? 250 : limit

    ds = if params[:sort_by]
           params[:sort_by] =~ /^(\w+)(\.desc|\.asc)?$/
           ds.order(params[:sort_by])
         else
           ds.order(:id.desc)
         end

    ds = ds.limit(limit, start)
    [ds, total, start, limit]
  end

  def generate(ds)
    ds.instance_exec {
      self.values.dup.merge(:uuid=>canonical_uuid)
    }
  end

  def collection_respond_with(ds)
    ds, total, start, limit  = paging_params_filter(ds)

    ds = ds.all.map {|i|
      generate(i)
    }
    respond_with([{
                    :total => total,
                    :start => start,
                    :limit => limit,
                    :results=> ds
                  }])
  end

  def to_utc(time)
    begin
      case time
        when String
          Time.iso8601(time).utc
        when Time
          time.utc
      else
        raise ArgumentError
       end
    rescue ArgumentError
      raise("Invalid Parameter #{time}")
    end
  end

end
