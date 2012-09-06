class ApiController < ApplicationController
  layout false
  respond_to :json
  skip_before_filter :login_required

  def find_by_uuid(model_class, uuid)
    if model_class.is_a?(Symbol)
      model_class = Sequel::Model.const_get(model_class, false)
    end
    raise "Invalid UUID Syntax: #{uuid}" if !model_class.valid_uuid_syntax?(uuid)
    item = model_class[uuid] || raise("Unknown UUID Resource", uuid.to_s)
  end

  def datetime_range_params_filter(param, ds)
    since_time = until_time = nil
    since_key = "#{param}_since"
    until_key = "#{param}_until"
    if params[since_key]
      since_time = begin
                     Time.iso8601(params[since_key].to_s).utc
                   rescue ArgumentError
                     raise E::InvalidParameter, since_key
                   end
    end
    if params[until_key]
      until_time = begin
                     Time.iso8601(params[until_key].to_s).utc
                   rescue ArgumentError
                     raise E::InvalidParameter, until_key
                   end
    end
    
    ds = if since_time && until_time
           if !(since_time < until_time)
             raise E::InvalidParameter, "#{since_key} is larger than #{until_key}"
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
end
