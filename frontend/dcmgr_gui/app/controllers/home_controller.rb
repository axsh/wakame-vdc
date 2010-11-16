class HomeController < ApplicationController
  def index
    @informations = Information.all
  end
end
