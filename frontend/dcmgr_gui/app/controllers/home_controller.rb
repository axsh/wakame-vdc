class HomeController < ApplicationController
  def index
    @informations = Frontend::Models::Information.all
  end
end
