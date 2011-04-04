class ApplicationController < ActionController::Base
  protect_from_forgery
  include Authentication
  before_filter :login_required
  before_filter :set_locale

  def set_locale
    I18n.locale = I18n.default_locale.to_s
    locale = extract_locale_from_accept_language_header
    I18n.locale = locale if locale
    I18n.locale = params[:locale] if params[:locale]
    session[:locale] = I18n.locale
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