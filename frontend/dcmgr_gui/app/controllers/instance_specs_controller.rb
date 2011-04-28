class InstanceSpecsController < ApplicationController
  respond_to :json
  
  def index
  end
  
  def show_instance_specs
    instance_specs = DcmgrResource::InstanceSpec.list
    respond_with(instance_specs[0], :to => [:json])
  end
end
