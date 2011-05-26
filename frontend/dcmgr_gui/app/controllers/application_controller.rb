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
      if is_dcmgr?(e)
        response.status = e.response.code 
        response.body = e.response.body
        response['X-Vdc-Request-Id'] = e.response['X-Vdc-Request-Id']  
      else
        raise
      end
    end
    to_a
  end

  def is_dcmgr?(response_data)
    if response_data.response['X-Vdc-Request-Id']
      true
    else
      false
    end
  end

  def set_locale
    language = params[:select_language] if params[:select_language]
    if language
      I18n.locale = language[:locale]
      session[:locale] = I18n.locale
    else
      if session[:locale]
        I18n.locale = session[:locale]
      elsif @current_user
        I18n.locale = @current_user.locale
      else
        I18n.locale = I18n.default_locale.to_s
      end
    end
    
    @locales = get_locales 
    @locale = I18n.locale
  end

  def get_locales
    locales = Array.new
    locales.push(['English','en'])
    locales.push(['日本語','ja'])
    locales
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
