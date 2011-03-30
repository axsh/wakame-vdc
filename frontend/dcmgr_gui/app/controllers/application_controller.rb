class ApplicationController < ActionController::Base
  protect_from_forgery
  include Authentication
  before_filter :login_required
  before_filter :set_locale

  def set_locale
    I18n.locale = I18n.default_locale.to_s
    I18n.locale = extract_locale_from_accept_language_header if extract_locale_from_accept_language_header
    I18n.locale = params[:locale] if params[:locale]
    session[:locale] = extract_locale_from_accept_language_header
  end

  private
  def extract_locale_from_accept_language_header
    if request.env['HTTP_ACCEPT_LANGUAGE'].nil?
      nil
    else
      request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
    end
  end

end