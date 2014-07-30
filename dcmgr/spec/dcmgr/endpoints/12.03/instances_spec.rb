# -*- coding: utf-8 -*-
require_relative 'helper'

describe "instances" do
  it "gets us some instances" do
    get "instances"
    puts last_response.errors
  end
end


