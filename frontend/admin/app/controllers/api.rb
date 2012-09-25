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

  get :notifications, :provides => :json do
    limit = params['limit'].nil? ? 10 : params['limit'].to_i
    start = params['start'].nil? ? 0 : params['start'].to_i
    sort  = SORTING.include?(params['sort']) ? params['sort'] : 'asc'

    @notifications = Notification.order(:id.send(sort)).limit(limit, start).alives.all
    results = []
    @notifications.each {|n|
      results << n.to_hash()
    }

    h = {
      :count => Notification.alives.count,
      :results => results
    }
    render h
  end

  get '/notifications/:id', :provides => :json do

    @notification = Notification.filter(:id => params[:id]).alives.first
    if @notification.nil?
      h = { :result => '' }
      return render h
    end

    h = {
      :count => 1,
      :result => @notification.to_hash
    }
    render h
  end

  delete '/notifications/:id', :provides => :json do
    @notification = Notification.filter({:id => params[:id]}).alives.first
    if @notification.nil?
      h = { :result => '' }
      return render h
    end

    @notification.deleted_at = Time.now
    @notification.save_changes

    h = {
      :result => @notification.to_hash
    }
    render h
  end

  post :notifications, :provides => :json do

    if params[:users] == ''
      distribution = 'all'
      users = []
    else
      distribution = 'any'
      users = params[:users].split(',')
    end

    @notification = Notification.new
    @notification.distribution = distribution
    @notification.title = params[:title]

    if !params[:publish_date_to].nil?
      @notification.publish_date_to = Time.iso8601(params[:publish_date_to])
    end

    if !params[:publish_date_from].nil?
      @notification.publish_date_from = Time.iso8601(params[:publish_date_from])
    end

    @notification.article = params[:article]
    if @notification.valid?
      Notification.db.transaction do
        result = @notification.save
        users.each do |user_id|
          NotificationUser.create :notification_id => result.id, :user_id => user_id
        end
      end
      h = {
       :result => @notification.to_hash
      }

      # TODO: better notification system.
      flash[:message] = 'お知らせを作成しました。'

    else
      h = {
       :result => {},
       :errors => @notification.errors
      }
      status 400
    end
    render h
  end

  put '/notifications/:id', :provides => :json do

    @notification = Notification.filter(:id => params[:id]).alives.first
    if @notification.nil?
      h = { :result => '' }
      return render h
    end

    if params[:title]
      @notification.title = params[:title]
    end

    if params[:users]
      @notification.users = params[:users]
    end


    if params[:publish_date_to]
      @notification.publish_date_to = Time.iso8601(params[:publish_date_to])
    end

    if params[:publish_date_from]
      @notification.publish_date_from = Time.iso8601(params[:publish_date_from])
    end

    if params[:article]
      @notification.article = params[:article]
    end

    if @notification.valid?
      @notification.save_changes

      # TODO: better notification system.
      flash[:message] = 'お知らせを更新しました。'
    end

    h = {
      :result => @notification.to_hash
    }

    render h
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
