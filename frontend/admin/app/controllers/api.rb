# -*- coding: utf-8 -*-

DcmgrAdmin.controllers :api do
  require 'spoof_token_authentication'
  disable :layout

  SORTING = ['asc', 'desc'].freeze

  BODY_PARSER = {
    'application/json' => proc { |body| ::JSON.load(body) },
    'text/json' => proc { |body| ::JSON.load(body) },
  }

  before do
    next if request.content_type == 'application/x-www-form-urlencoded'
    next if !(request.content_length.to_i > 0)
    parser = BODY_PARSER[(request.content_type || request.preferred_type)]
    hash = if parser.nil?
             error(400, 'Invalid content type.')
           else
             begin
               parser.call(request.body)
             rescue => e
               error(400, 'Invalid request body.')
             end
           end
    @params.merge!(hash)
  end

  get :generate_token, :provides => :json do
    timestamp = Time.now.to_s
    token = SpoofTokenAuthentication.generate(params[:id], timestamp)
    results = {
      :token => token,
      :timestamp => timestamp,
      :user_id => params[:id]
    }
    h = {:results =>results}
    render h
  end
end
