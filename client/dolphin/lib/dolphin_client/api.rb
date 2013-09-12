# -*- coding: utf-8 -*-
require 'weary'

module DolphinClient
  class API < Weary::Client

    use Weary::Middleware::ContentType, 'application/json'
    use Rack::Lint

    get :get_events, "events" do |resource|
    end

    post :post_events, "events" do |resource|
    end

    get :get_notifications, "notifications" do |resource|
    end

    post :post_notifications, "notifications" do |resource|
    end
  end
end
