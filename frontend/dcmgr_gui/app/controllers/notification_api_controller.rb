# -*- coding: utf-8 -*-

class NotificationApiController < ApiController
  SORTING = ['asc', 'desc'].freeze

  def index
    limit = params['limit'].nil? ? 10 : params['limit'].to_i
    start = params['start'].nil? ? 0 : params['start'].to_i
    sort  = SORTING.include?(params['sort']) ? params['sort'] : 'asc'
    @notifications = Notification.order(:id.send(sort)).limit(limit, start).alives

    results = []
    @notifications.each {|n|
      results << n.to_hash()
    }

    h = {
      :count => Notification.alives.count,
      :results => results
    }
    render :json => h
  end

  def show
    @notification = Notification[params[:id]]
    if @notification.nil?
      return render :json => {}
    end

    respond_with(generate(@notification), :to=>[:json])
  end

  def destroy
    @notification = Notification[params[:id]]
    if @notification.nil?
      return render :json => h
    end

    @notification.deleted_at = Time.now
    @notification.save_changes

    h = {
      :result => @notification.to_hash
    }
    respond_with(generate(@notification), :to=>[:json])
  end

  def create
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
      @notification.publish_date_to = to_utc(params[:publish_date_to])
    end

    if !params[:publish_date_from].nil?
      @notification.publish_date_from = to_utc(params[:publish_date_from])
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

    else
      h = {
       :result => {},
       :errors => @notification.errors
      }
      status 400
    end
    render :json => h
  end

  def update
    @notification = Notification[params[:id]]
    if @notification.nil?
      h = { :result => '' }
      return render h
    end

    if params[:title]
      @notification.title = params[:title]
    end

    if params[:publish_date_to]
      @notification.publish_date_to = to_utc(params[:publish_date_to])
    end

    if params[:publish_date_from]
      @notification.publish_date_from = to_utc(params[:publish_date_from])
    end

    if params[:article]
      @notification.article = params[:article]
    end

    if @notification.valid?
      @notification.save_changes
    end

    h = {
      :result => @notification.to_hash
    }

    render :json => h
  end

end
