class InformationController < ApplicationController
  def index
  end
  
  def rss
    @feed_title = "Wakame VDC Informations"
    @informations = Information.all
    render :layout => false
  end
end
