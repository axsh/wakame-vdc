# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::V1203

  class Network < Base
    initialize_user_result nil, [:account_id,
                                 :uuid,
                                 :ipv4_network,
                                 :ipv4_gw,
                                 :prefix,
                                 :metric,
                                 :domain_name,
                                 :dns_server,
                                 :dhcp_server,
                                 :metadata_server,
                                 :metadata_server_port,
                                 # :nat_network_id,
                                 # :dc_network_id,
                                 :description,
                                 :created_at,
                                 :updated_at,
                                 # :gateway_network_id,
                                 :network_mode,
                                 :bandwidth,
                                 :service_type,
                                 :display_name,
                                 # :bandwidth_mark,
                                ], [:dc_network], [:network_services]
    initialize_user_result 'DcNetwork', [:uuid,
                                         :name,
                                         :description,
                                         :offering_network_modes,
                                         :created_at,
                                         :updated_at,
                                        ]
    initialize_user_result 'NetworkService', [:name,
                                              :description,
                                              :created_at,
                                              :updated_at,
                                             ]

    module ClassMethods
      include Hijiki::DcmgrResource::Common::ListMethods::ClassMethods

      def list(params = {})
        super(params.merge({:state=>'alive_with_terminated'}))
      end
      
      def create(params)
        object = self.new
        object.display_name = params[:display_name] if params[:display_name]
        object.description = params[:description] if params[:description]
        object.domain_name = params[:domain_name] if params[:domain_name]
        object.dc_network = params[:dc_network] if params[:dc_network]
        object.network_mode = params[:network_mode]
        object.network = params[:ipv4_network]
        object.gw = params[:ipv4_gw] if params[:ipv4_gw]
        object.prefix = params[:prefix]
        object.ip_assignment = params[:ip_assignment] if params[:ip_assignment]
        object.editable = params[:editable] if params[:editable]
        
        object.service_dhcp = params[:service_dhcp] if params[:service_dhcp]
        object.service_dns = params[:service_dns] if params[:service_dns]
        object.service_gateway = params[:service_gateway] if params[:service_gateway]

        object.dhcp_range = params[:dhcp_range] if params[:dhcp_range]

        object.save
        object
      end
    end
    extend ClassMethods

    def find_vif(vif_id)
      NetworkVif.find(vif_id, :params => { :network_id => self.id })
    end

    def find_service(service_name)
      NetworkService.find(service_name, :params => { :network_id => self.id })
    end

    def list_services
      NetworkService.list(:network_id => self.id)
    end

    def delete_service(vif_id, name)
      self.delete('services', {:vif_id => vif_id, :name => name})
    end

    def get_dhcp_ranges
      self.get(:dhcp_ranges)
    end

    def add_dhcp_range(range_begin, range_end)
      self.put('dhcp_ranges/add', { :range_begin => range_begin, :range_end => range_end })
    end

    def remove_dhcp_range(range_begin, range_end)
      self.put('dhcp_ranges/remove', { :range_begin => range_begin, :range_end => range_end })
    end

    def attach(vif_id)
      self.put("vifs/#{vif_id}/attach")
    end

    def detach(vif_id)
      self.put("vifs/#{vif_id}/detach")
    end
  end

end
