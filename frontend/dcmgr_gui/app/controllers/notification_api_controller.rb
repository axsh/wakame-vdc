# -*- coding: utf-8 -*-

class NotificationApiController < ApiController
  SORTING = ['asc', 'desc'].freeze

  def index
    distribution = params['distribution']
    users = params['users']
    limit = params['limit'].nil? ? 10 : params['limit'].to_i
    start = params['start'].nil? ? 0 : params['start'].to_i
    sort  = SORTING.include?(params['sort']) ? params['sort'] : 'asc'
    @notifications = Notification

    if distribution
      if users
        uuids = User.split_uuid(params[:users])
        users = User.get_user_ids(uuids)
      end
      @notifications = Notification.notifications(distribution, users)
    else
      @notifications = Notification
    end

    @notifications = @notifications.order(:id.send(sort)).limit(limit, start)

    if params[:display_begin_at] && params[:display_end_at]
      @notifications = @notifications.filter('display_begin_at >= ?', to_utc(params[:display_begin_at]))
      @notifications = @notifications.filter('display_end_at <= ?', to_utc(params[:display_end_at]))
    end

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

    h = @notification.to_hash
    h[:users] = Notification[params[:id]].notification_users.collect {|u| User[u.user_id].canonical_uuid }
    respond_with(h, :to=>[:json])
  end

  def destroy
    @notification = Notification[params[:id]]
    if @notification.nil?
      return render :json => h
    end


    Notification.db.transaction do
      @notification.deleted_at = Time.now
      @notification.save_changes
      @notification.notification_users.each do |n|
        n.destroy
      end
    end

    h = {
      :result => @notification.to_hash
    }
    respond_with(generate(@notification), :to=>[:json])
  end

  def create

    users = []
    distribution = params[:users] == '' ? 'all' : 'any'
    if distribution == 'any'
      uuids = User.split_uuid(params[:users])
      users = User.get_user_ids(uuids)
      raise "User not found #{params[:users]}" if !users
    end

    @notification = Notification.new
    @notification.distribution = distribution
    @notification.title = params[:title]

    if !params[:display_end_at].nil?
      @notification.display_end_at = to_utc(params[:display_end_at])
    end

    if !params[:display_begin_at].nil?
      @notification.display_begin_at = to_utc(params[:display_begin_at])
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

    users = []
    distribution = params[:users] == '' ? 'all' : 'any'
    if distribution == 'any'
      uuids = User.split_uuid(params[:users])
      users = User.get_user_ids(uuids)
      raise "User not found #{params[:users]}" if !users
    end

    @notification.distribution = distribution

    if params[:title]
      @notification.title = params[:title]
    end

    if params[:display_end_at]
      @notification.display_end_at = to_utc(params[:display_end_at])
    end

    if params[:display_begin_at]
      @notification.display_begin_at = to_utc(params[:display_begin_at])
    end

    if params[:article]
      @notification.article = params[:article]
    end

    if @notification.valid?
      Notification.db.transaction do
        @notification.save_changes
        if users
          @notification.notification_users.each do |n|
            n.destroy
          end

          users.each do |user_id|
            NotificationUser.create :notification_id => @notification.id, :user_id => user_id
          end
        end
      end
    end

    h = {
      :result => @notification.to_hash
    }

    render :json => h
  end

end
