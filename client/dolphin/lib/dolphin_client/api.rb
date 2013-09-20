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

    def finish(response)
      status = 400
      body = {}
      headers = {}

      begin
        if response.is_a?(Weary::Response) && response.success?
          status = response.status
          headers = response.header
          body = MultiJson.load(response.body)
        else
          status = 400
          body = 'failed request to dolphin.'
        end
      rescue => e
        raise e
      end
      [status, body, headers]
    end
  end
end
