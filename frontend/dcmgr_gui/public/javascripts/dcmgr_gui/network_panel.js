DcmgrGUI.prototype.networkPanel = function(){
  var total = 0;
  var maxrow = 10;
  var page = 1;
  var list_request = { 
    "url" : DcmgrGUI.Util.getPagePath('/networks/list/',page),
    "data" : DcmgrGUI.Util.getPagenateData(page,maxrow)
  };
    
  DcmgrGUI.List.prototype.getEmptyData = function(){
    return [{
      "uuid":'',
      "created_at":'',
    }]
  }
  
  DcmgrGUI.Detail.prototype.getEmptyData = function(){
    return {
      "uuid" : "-",
      "created_at" : "-",
      "updated_at" : "-",
    }
  }

  var c_pagenate = new DcmgrGUI.Pagenate({
    row:maxrow,
    total:total
  });
  
  var c_list = new DcmgrGUI.List({
    element_id:'#display_networks',
    template_id:'#networksListTemplate',
    maxrow:maxrow,
    page:page
  });
  
  c_list.setDetailTemplate({
    template_id:'#networksDetailTemplate',
    detail_path:'/networks/show/'
  });
  
  var create_button_name = $.i18n.prop('create_button');
  var close_button_name = $.i18n.prop('close_button');
  var update_button_name = $.i18n.prop('update_button');

  //
  // Content Update:
  //

  c_list.element.bind('dcmgrGUI.contentChange',function(event,params){
    var network = params.data.network;
    c_pagenate.changeTotal(network.total);
    c_list.setData(network.results);
    c_list.multiCheckList(c_list.detail_template);

    c_list.element.find(".edit_network").each(function(key,value){
      $(this).button({ disabled: false });
      var uuid = $(value).attr('id').replace(/edit_(nw-[a-z0-9]+)/,'$1');
      if( uuid ){
        $(this).bind('click',function(){
          bt_edit_network.open({"ids":[uuid]});
        });
      } else {
        $(this).button({ disabled: true });
      }
    });

    var edit_network_buttons = {};
    edit_network_buttons[close_button_name] = function() { $(this).dialog("close"); };
    edit_network_buttons[update_button_name] = function(event) {
      var network_id = $(this).find('#network_id').val();
      var display_name = $(this).find('#network_display_name').val();
      var data = 'display_name=' + display_name;

      var request = new DcmgrGUI.Request;
      request.put({
        "url": '/networks/'+ network_id +'.json',
        "data": data,
        success: function(json, status){
          bt_refresh.element.trigger('dcmgrGUI.refresh');
        }
      });
      $(this).dialog("close");
    }

    bt_edit_network = new DcmgrGUI.Dialog({
      target:'.edit_network',
      width:600,
      height:600,
      title:$.i18n.prop('edit_network_header'),
      path:'/edit_network',
      button: edit_network_buttons,
      callback: function(){
        var self = this;

        var network_id = $(this).find('#network_id').val();
        var display_name = $(this).find('#network_display_name').val();

        var params = { 'button': bt_edit_network, 'element_id': 1 };
        $(this).find('#network_display_name').bind('paste', params, DcmgrGUI.Util.availableTextField);
        $(this).find('#network_display_name').bind('keyup', params, DcmgrGUI.Util.availableTextField);

        var request = new DcmgrGUI.Request;

        var refresh_network_services = function() {
          request.get({
            "url": '/networks/'+ network_id +'/services.json',
            "data": "",
            success: function(json,status){
              var results = json[0].network_service.results;
              var network_services = $(self).find('#network_services');
              network_services.html('');

              for (var i=0; i < results.length ; i++) {
                service_html =
                  '<fieldset id="network_services_field">' +
                  '<legend>' + $.i18n.prop('edit_network_service_header') + '</legend><legend>' +
                  '</legend><table cellspacing="5" cellpadding="5"><tbody>' +
                  '<tr><td>' + $.i18n.prop('edit_network_service_name') + ': </td><td>' + results[i].result.name + '</td></tr>' +
                  '<tr><td>' + $.i18n.prop('edit_network_service_vif_id') + ': </td><td>' + results[i].result.network_vif_id + '</td></tr>' +
                  '<tr><td>' + $.i18n.prop('edit_network_service_address') + ': </td><td>' + results[i].result.address + '</td></tr>' +
                  '<tr><td>' + $.i18n.prop('edit_network_service_mac_addr') + ': </td><td>' + results[i].result.mac_addr + '</td></tr>' +
                  '<tr><td>' + $.i18n.prop('edit_network_service_incoming_port') + ': </td><td>' + results[i].result.incoming_port + '</td></tr>' +
                  '<tr><td>' + $.i18n.prop('edit_network_service_outgoing_port') + ': </td><td>' + results[i].result.outgoing_port + '</td></tr>' +
                  '</tbody></table></fieldset>';
                network_services.append(service_html);
              }
            }
          });
        };

        var refresh_dhcp_ranges = function() {
          request.get({
            "url": '/networks/'+ network_id +'/dhcp_ranges.json',
            "data": "",
            success: function(json,status){
              var select_dhcp_ranges = $(self).find('#select_dhcp_ranges');
              select_dhcp_ranges.html('');

              for (var i=0; i < json.length ; i++) {
                var value = json[i][0] + ' - ' + json[i][1];
                var html = '<option id="'+i+'" value="'+ value +'">'+ value +'</option>';
                select_dhcp_ranges.append(html);
              }
            }
          });
        };

        var change_dhcp_range = function(use_command){
          var data =
            "range_begin=" + $(self).find('#begin_dhcp_range').val() +
            "&range_end=" + $(self).find('#end_dhcp_range').val();

          request.put({
            "url": '/networks/' + network_id + '/dhcp_ranges/' + use_command + '.json',
            "data": data,
            success: function(json,status) {
              $(self).find('#begin_dhcp_range').val("");
              $(self).find('#end_dhcp_range').val("");
              refresh_dhcp_ranges();
            }
          });
        };
        
        $(self).find('#add_dhcp_range').click(function(){ change_dhcp_range('add'); });
        $(self).find('#remove_dhcp_range').click(function(){ change_dhcp_range('remove'); });

        $(self).find('#service_add').click(function() {
          var service_name = $(self).find('#service_name').val();
          var service_address = $(self).find('#service_address').val();
          var service_incoming_port = $(self).find('#service_incoming_port').val();
          var service_outgoing_port = $(self).find('#service_outgoing_port').val();

          var data = "name=" + service_name
            + "&ipv4=" + service_address
            + "&incoming_port=" + service_incoming_port
            + "&outgoing_port=" + service_outgoing_port;
          
          request.post({
            "url": '/networks/'+ network_id +'/services.json',
            "data": data,
            success: function(json,status) {
              refresh_network_services();
            }
          });          
        });

        parallel({
          // get dhcp ranges
          dhcp_ranges: refresh_dhcp_ranges(),
          network_services: refresh_network_services()
        })
      }
    });

  });
  
  c_list.filter.add(function(data){
    var results = data.network.results;
    var size = results.length;
    for(var i = 0; i < size; i++) {
      results[i].result.created_at = DcmgrGUI.date.parseISO8601(results[i].result.created_at);
      results[i].result.created_at = DcmgrGUI.date.setTimezone(results[i].result.created_at, dcmgrGUI.getConfig('time_zone'));
      results[i].result.created_at = DcmgrGUI.date.getI18n(results[i].result.created_at);
    }
    return data;
  });

  var bt_refresh  = new DcmgrGUI.Refresh();
  
  bt_refresh.element.bind('dcmgrGUI.refresh',function(){
    c_list.page = c_pagenate.current_page;
    list_request.url = DcmgrGUI.Util.getPagePath('/networks/list/',c_list.page);
    list_request.data = DcmgrGUI.Util.getPagenateData(c_pagenate.start,c_pagenate.row);
    c_list.element.trigger('dcmgrGUI.updateList',{request:list_request})
    
    //update detail
    $.each(c_list.checked_list,function(check_id,obj){
      $($('#detail').find('#'+check_id)).remove();
      c_list.checked_list[check_id].c_detail.update({
        url:DcmgrGUI.Util.getPagePath('/networks/show/',check_id)
      },true);
    });
  });
  
  c_pagenate.element.bind('dcmgrGUI.updatePagenate',function(){
    c_list.clearCheckedList();
    $('#detail').html('');
    bt_refresh.element.trigger('dcmgrGUI.refresh');
  });

  //
  // Create Network:
  //

  var create_network_buttons = {};
  create_network_buttons[close_button_name] = function() { $(this).dialog("close"); };  
  create_network_buttons[create_button_name] = function() {
    var display_name = $(this).find('#display_name').val();
    var description = $(this).find('#description').val();
    var domain_name = $(this).find('#domain_name').val();
    var dc_network = $(this).find('#dc_network').val();
    var network_mode = $(this).find('#network_mode').val();
    var ipv4_network = $(this).find('#ipv4_network').val();
    var ipv4_gw = $(this).find('#ipv4_gw').val();
    var prefix = $(this).find('#prefix').val();
    var ip_assignment = $(this).find('#ip_assignment').val();

    var service_address = $(this).find('#service_address').val();

    var data = "&display_name="+display_name
          +"&description="+description
          +"&domain_name="+domain_name
          +"&dc_network="+dc_network
          +"&network_mode="+network_mode
          +"&ipv4_network="+ipv4_network
          +"&ipv4_gw="+ipv4_gw
          +"&prefix="+prefix
          +"&network_mode="+network_mode
          +"&ip_assignment="+ip_assignment;
    
    $('#service_checkbox:checked').each(function() {
      data = data + "&service_" + $(this).val() + "=" + service_address;
    });

    request = new DcmgrGUI.Request;
    request.post({
      "url": '/networks',
      "data": data,
      success: function(json,status){
       bt_refresh.element.trigger('dcmgrGUI.refresh');
      }
    });

    $(this).dialog("close");
  }

  var bt_create_network = new DcmgrGUI.Dialog({
    target:'.create_network',
    width:583,
    height:600,
    title:$.i18n.prop('create_network_header'),
    path:'/create_network',
    callback: function(){
      var self = this;

      var request = new DcmgrGUI.Request;
      var is_ready = {
        'dc_network': false,
        'display_name': false,
      }      

      var ready = function(data) {
        if(data['dc_network'] == true &&
           data['display_name'] == true) {  
          bt_create_network.disabledButton(1, false);
        } else {
          bt_create_network.disabledButton(1, true);
        }
      }

      $(this).find('#display_name').keyup(function(){
       if( $(this).val() ) {
         is_ready['display_name'] = true;
         ready(is_ready);
       } else {
         is_ready['display_name'] = false;
         ready(is_ready);
       }
      });

      parallel({
        //get dc_networks
        dc_networks: 
          request.get({
            "url": '/dc_networks/allows_new_networks.json',
            "data": "",
            success: function(json,status){
              var create_select_item = function(name) {
                var select_html = '<select id="' + name + '" name="' + name + '"></select>';
                $(self).find('#select_' + name).empty().html(select_html);
                return $(self).find('#' + name);
              }

              var append_select_item = function(select_item, name, value) {
                select_item.append('<option value="'+ value +'">' + name + '</option>');
              }

              var create_select = function(name, results) {
                var select_obj = create_select_item(name);

                for (var i=0; i < results.length ; i++) {
                  append_select_item(select_obj, results[i].result.name, results[i].result.uuid)
                }
                return select_obj;
              }

              var results = json.dc_network.results;
              var size = results.length;

              var select_dc_network = create_select('dc_network', results);

              // Update network_mode depending on selected dc_network.
              var dc_offering = {}

              for (var i=0; i < results.length ; i++) {
                dc_offering[results[i].result.uuid] = results[i].result.offering_network_modes
              }

              var update_network_modes = function(){
                var select_network_mode = create_select_item('network_mode');
                var current_dc_network = select_dc_network.val();

                $.each(dc_offering[current_dc_network], function(key, value) {
                  append_select_item(select_network_mode, value, value)
                });
              };

              update_network_modes();

              select_dc_network.change(update_network_modes);

              is_ready['dc_network'] = true;
              ready(is_ready);
            }
          }),

      });

    },
    button: create_network_buttons
  });

  bt_create_network.target.bind('click',function(){
    bt_create_network.open();
    bt_create_network.disabledButton(1, true);
  });

  $(bt_create_network.target).button({ disabled: false });
  $(bt_refresh.target).button({ disabled: false });

 //list
  c_list.setData(null);
  c_list.update(list_request,true);  
}
