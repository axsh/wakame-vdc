# -*- coding: utf-8 -*-

class ApplicationController < ActionController::Base
  protect_from_forgery
  include Authentication
  before_filter :login_required
  before_filter :set_locale
  
  def dispatch(name, request)
    begin 
      super
    rescue Sequel::DatabaseConnectionError => e
      response.status = 500
      response.body = 'Database connection faild.'
    rescue ActiveResource::ConnectionError => e 
      if is_dcmgr?(e.response.body)
        response.status = e.response.code 
        response.body = e.response.body
      else
        raise
      end
    end
    to_a
  end

  def is_dcmgr?(response_data)
    begin
      if json = JSON.parser.new(response_data)
        data = json.parse()
        if data.key?('error') && data.key?('code') && data.key?('message')
          true
        else
          false
        end
      end
    rescue JSON::ParserError, TypeError
      false
    end
  end

  def set_locale
    language = params[:select_language] if params[:select_language]
    if language
      I18n.locale = language['locale']
    else
      if session[:locale]
        I18n.locale = session[:locale]
      else
        I18n.locale = I18n.default_locale.to_s
      end
    end
    
    session[:locale] = I18n.locale
    @locale = Array.new
    @locale.push(['English','en'])
    @locale.push(['日本語','ja'])
  end

  private
  def extract_locale_from_accept_language_header
    if request.env['HTTP_ACCEPT_LANGUAGE'].nil?
      nil
    else
      parsed_locale = request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
      I18n.available_locales.include?(parsed_locale.to_sym) ? parsed_locale : I18n.default_locale.to_s
    end
  end

end
