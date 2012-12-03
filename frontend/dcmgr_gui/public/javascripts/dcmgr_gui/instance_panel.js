DcmgrGUI.prototype.instancePanel = function(){
  var total = 0;
  var maxrow = 10;
  var page = 1;
  var list_request = {
    "url" : DcmgrGUI.Util.getPagePath('/instances/list/',1),
    "data" : DcmgrGUI.Util.getPagenateData(page,maxrow)
  };

  DcmgrGUI.List.prototype.getEmptyData = function(){
    return [{
      "id":'',
      "instance_id":'',
      "owner":'',
      "wmi_id":'',
      "state":'',
      "private_ip":'',
      "type":''
    }];
  };

  DcmgrGUI.Detail.prototype.getEmptyData = function(){
    return {
      "instance_id":'-',
      "wmi_id":'-',
      "zone":'-',
      "security_groups":'-',
      "type":'-',
      "status":'-',
      "owner":'-'
    };
  };

  var close_button_name = $.i18n.prop('close_button');
  var terminate_button_name = $.i18n.prop('terminate_button');
  var reboot_button_name = $.i18n.prop('reboot_button');
  var update_button_name =$.i18n.prop('update_button');
  var backup_button_name =$.i18n.prop('backup_button');
  var poweroff_button_name =$.i18n.prop('poweroff_button');
  var poweron_button_name =$.i18n.prop('poweron_button');

  var c_pagenate = new DcmgrGUI.Pagenate({
    row:maxrow,
    total:total
  });

  var c_list = new DcmgrGUI.List({
    element_id:'#display_instances',
    template_id:'#instancesListTemplate',
    maxrow:maxrow,
    page:page
  });

  c_list.setDetailTemplate({
    template_id:'#instancesDetailTemplate',
    detail_path:'/instances/show/'
  });

  c_list.element.bind('dcmgrGUI.contentChange',function(event,params){
    var instance = params.data.instance;
    c_pagenate.changeTotal(instance.total);
    c_list.setData(instance.results);
    c_list.multiCheckList(c_list.detail_template);
    c_list.element.find(".edit_instance").each(function(key,value){
      $(this).button({ disabled: false });
      var uuid = $(value).attr('id').replace(/edit_(i-[a-z0-9]+)/,'$1');
      if( uuid ){
        $(this).bind('click',function(){
          bt_edit_instance.open({"ids":[uuid]});
        });
      } else {
        $(this).button({ disabled: true });
      }
    });

    var edit_instance_buttons = {};
    edit_instance_buttons[close_button_name] = function() { $(this).dialog("close"); };
    edit_instance_buttons[update_button_name] = function(event) {
      var self = this;
      var instance_id = $(this).find('#instance_id').val();
      var display_name = $(this).find('#instance_display_name').val();

      var query = ['display_name=' + display_name,
                   'monitoring[enabled]=' + $(this).find('#monitoring_enabled').is(':checked'),
                   'ssh_key_id=' + $(this).find("#ssh_key_pair").val()
                  ];
      $.each($(this).find('#right_select_list').find('option'), function(i){
        query.push("security_groups[]="+ $(this).val());
      });

      orig_len = query.length;
      _.each(['#mailaddr_0', '#mailaddr_1', '#mailaddr_2'], function(id){
        if( _.isString($(self).find(id).val()) && $(self).find(id).val() != ""){
          query.push("monitoring[mail_address][]="+$(self).find(id).val());
        }
      });
      if(query.length == orig_len){
        // Clear recipient list
        query.push("monitoring[mail_address]=");
      }

      if( !bt_edit_instance.monitor_selector.validate() ){
        return false;
      }

      var request = new DcmgrGUI.Request();
      parallel({
        instance: function(){
          request.put({
            "url": '/instances/'+ instance_id +'.json',
            "data": query.join('&'),
            success: function(json, status){
              bt_refresh.element.trigger('dcmgrGUI.refresh');
            }
          });
        },
        monitoring: function(){
          request.post({
            "url": '/network_vifs/'+ select_current_vif[0] +'/monitors.json',
            "data": bt_edit_instance.monitor_selector.queryParams(),
            success: function(json, status){
            }
          });
        }
      });
      $(this).dialog("close");
    };

    var bt_edit_instance = new DcmgrGUI.Dialog({
      target:'.edit_instance',
      width:550,
      height:640,
      title:$.i18n.prop('edit_instance_header'),
      path:'/edit_instance',
      button: edit_instance_buttons,
      callback: function(){
        var self = this;

        $(this).find('#left_select_list').mask($.i18n.prop('loading_parts'));
        $(this).find('#right_select_list').mask($.i18n.prop('loading_parts'));

        var ready = function(data) {
          if($(self).find('#monitoring_enabled').is(':checked')){
            _.chain(['#mailaddr_0', '#mailaddr_1', '#mailaddr_2']).map(function(id){
              var v = $(self).find(id).val();
              if(v.length > 0){
                return [(v.length > 0), /^[^@]+@[a-z0-9A-Z][a-z0-9A-Z\.\-]+$/.test(v)];
              }else{
                return [false, false];
              }
            }).tap(function(tuple_lst){
              if(_.all(tuple_lst, function(i){
                return (i[0] == false && i[1] == false);
              })){
                // Can not submit when none of address fields is filled.
                data['monitoring'] = false;
              }else{
                // Can submit when empty and validation passed address fields exist.
                data['monitoring'] = _.all(tuple_lst, function(i){
                  return (i[0] == true && i[1] == true) || (i[0] == false && i[1] == false);
                });
              }
            });
          }else{
            data['monitoring'] = true;
          }
          
          if( data.monitoring ){
            data.monitoring = bt_edit_instance.monitor_selector.validate();
          }

          if(data['security_groups'] == true &&
             data['display_name'] == true &&
             data['networks'] == true &&
             data['monitoring'] == true &&
             data['monitoring_form'] == true) {
            bt_edit_instance.disabledButton(1, false);
          } else {
            bt_edit_instance.disabledButton(1, true);
          }
        };

        var is_ready = {
          'display_name' : true,
          'security_groups' : true,
          'networks' : false,
          'monitoring' : true,
          'monitoring_form' : false
        };

        var on_ready = function(size){
          if(size > 0) {
            is_ready['security_groups'] = true;
            ready(is_ready);
          } else {
            is_ready['security_groups'] = false;
            ready(is_ready);
          }
        };

        var params = {'name': 'display_name', 'is_ready': is_ready, 'ready': ready};
        $(this).find('#instance_display_name').bind('keyup paste cut', params, DcmgrGUI.Util.checkTextField);
        $(this).find('#monitoring_enabled').bind('click', {'name': 'monitoring', 'is_ready': is_ready, 'ready': ready},
                                                 DcmgrGUI.Util.checkTextField).bind('click', function(e){
                                                   _.each(['#mailaddr_0', '#mailaddr_1', '#mailaddr_2'], function(id){
                                                     if( $(e.target).is(":checked") ){
                                                       $(self).find(id).removeAttr("disabled");
                                                     }else{
                                                       $(self).find(id).attr("disabled", "disabled");
                                                     }
                                                   });
                                                 });
        $(this).find('.mailaddr_form').bind('keyup paste cut',
                                            {'name': 'monitoring', 'is_ready': is_ready, 'ready': ready},
                                            DcmgrGUI.Util.checkTextField);
        // All new input forms will get realtime validation.
	$(this).find('#monitor_item_list input[type=text]').live('keyup paste cut',
                                                                 {'name': 'monitoring', 'is_ready': is_ready, 'ready': ready},
                                                                 DcmgrGUI.Util.checkTextField);

        bt_edit_instance.monitor_selector = new DcmgrGUI.VifMonitorSelector($(this).find('#monitor_item_list'));

        var create_attach_vif = function(index) {
          var select_html = '<button id="attach_button_eth' + index + '" name="attach_button_eth' + index + '")">Attach</button>';

          $(self).find('#vif_button_eth' + index).empty().html(select_html);
          $(self).find('#attach_button_eth' + index).click(function(){
            if ($(self).find('#eth' + index).val() != 'disconnected') {
              attach_vif($(self).find('#eth' + index).val(), select_current_vif[index], index);
            }
          });
        };

        var create_detach_vif = function(index) {
          var select_html = '<button id="detach_button_eth' + index + '" name="detach_button_eth' + index + '")">Detach</button>';

          $(self).find('#vif_button_eth' + index).empty().html(select_html);
          $(self).find('#detach_button_eth' + index).click(function(){
            detach_vif(select_current_nw[index], select_current_vif[index], index);
          });
        };

        var update_eth_network_id = function(index) {
          if (select_current_nw[index]) {
            $(self).find('#eth'+index+'_network_id').empty().html(select_current_nw[index]);
            $(self).find('#eth'+index).val(select_current_nw[index]).attr('selected',true);
            create_detach_vif(index);
          } else {
            $(self).find('#eth'+index+'_network_id').empty().html("disconnected");
            $(self).find('#eth'+index).val('disconnected').attr('selected',true);
            create_attach_vif(index);
          }
        };

        function attach_vif(network_id, vif_id, index) {
          var data = "network_id=" + network_id + "&vif_id=" + vif_id;

          request = new DcmgrGUI.Request();
          request.put({
            "url": '/networks/attach',
            "data": data,
            success: function(json,status){
              select_current_nw[index] = network_id;
              update_eth_network_id(index);
            }
          });
        }

        function detach_vif(network_id, vif_id, index) {
          var data = "network_id=" + network_id + "&vif_id=" + vif_id;

          request = new DcmgrGUI.Request();
          request.put({
            "url": '/networks/detach',
            "data": data,
            success: function(json,status){
              select_current_nw[index] = null;
              update_eth_network_id(index);
            }
          });
        }

        var request = new DcmgrGUI.Request;
        var instance_id = $('#instance_id').val();
        parallel({
          monitoring: function(){
            request.get({
              "url": '/network_vifs/'+select_current_vif[0]+'/monitors.json',
              "data": "",
              success: function(json,status) {
                for(var i in json) {
                  bt_edit_instance.monitor_selector.addItem(json[i].title, json[i]);
                }

                is_ready['monitoring_form'] = true;
                ready(is_ready);
              }
            });
          }
        });

        var instance = {};
        request.get({
          "url": '/instances/show/'+instance_id+'.json',
          "data": "",
          "async": false,
          success: function(json,status) {
            instance = json;
          }
        });

        parallel({
          security_groups:function(){
            var selected_groups = []
            if (instance.vif.length > 0) {
              selected_groups = instance.vif[0]['security_groups'];
            }

            request.get({
              "url": '/security_groups/all.json',
              "data": "",
              success: function(json,status){
                var data = [];
                var results = json.security_group.results;
                var size = results.length;

                for (var i=0; i < size ; i++) {
                  data.push({
                    "value" : results[i].result.uuid,
                    "id"    : results[i].result.uuid,
                    "name"  : results[i].result.display_name,
                    "selected" : !($.inArray(results[i].result.uuid, selected_groups) == -1)
                  });
                }

                var security_group = new DcmgrGUI.ItemSelector({
                  'left_select_id' : '#left_select_list',
                  'right_select_id' : '#right_select_list',
                  'data' : data,
                  'target' : self
                });

                $(self).find('#right_button').click(function(){
                  security_group.leftToRight();
                  on_ready(security_group.getRightSelectionCount());
                });

                $(self).find('#left_button').click(function(){
                  security_group.rightToLeft();
                  on_ready(security_group.getRightSelectionCount());
                });

              }
            });
          },
        ssh_keypairs: function(){

          request.get({
            "url": '/keypairs/all.json',
            "data": "",
            success: function(json,status){
              var select_html = '<select id="ssh_key_pair" name="ssh_key_pair"></select>';
              $(self).find('#select_ssh_key_pair').empty().html(select_html);

              var results = json.ssh_key_pair.results;
              var size = results.length;
              var select_keypair = $(self).find('#ssh_key_pair');
              if(size > 0) {
                is_ready['ssh_keypair'] = true;
              }

              for (var i=0; i < size ; i++) {
                var ssh_keypair_id = results[i].result.id;
                var ssh_keypair_name = results[i].result.display_name;
                var html = '<option id="'+ ssh_keypair_id +'" value="'+ ssh_keypair_id +'">'+ssh_keypair_name+' ('+ssh_keypair_id+')</option>'
                select_keypair.append(html);
              }

              select_keypair.change(function(){
                var selected_key_pair_id = select_keypair.val();
                var current_key_pair_id = instance.ssh_key_pair.uuid;

                if(selected_key_pair_id !== current_key_pair_id) {
                  $(self).find('#change_key_pair_message').html($.i18n.prop('change_key_pair_message'));
                } else {
                  $(self).find('#change_key_pair_message').html('');
                }
              });

              // current selected key pair
              $(self).find('#ssh_key_pair').val(instance.ssh_key_pair.uuid)
            }
          })
        },
        //get networks
        networks:
          request.get({
            "url": '/networks/all.json',
            "data": "",
            success: function(json,status){
              var create_select_eth = function(name, results, selected) {
                for (var i=0; i < size ; i++) {
                  var uuid = results[i].result.uuid;
                  var display_name = results[i].result.display_name;
                  $(self).find('#' + name).append('<option value="' + uuid + '" ' + (uuid == selected ? 'selected="selected"' : '') + '>' +
                                                  '[' + uuid + '] ' + display_name + '</option>');
                }
              }

              var results = json.network.results;
              var size = results.length;

              is_ready['networks'] = true;
              ready(is_ready);

              for (var i=0; i < select_current_nw.length ; i++) {
                update_eth_network_id(i);
                create_select_eth('eth' + i, results, select_current_nw[i]);
              }
            }
          })
        }).next(function(results) {
          $(self).find("#left_select_list").unmask();
          $(self).find("#right_select_list").unmask();
        });
      }
    });
  });

  c_list.filter.add(function(data){
    var results = data.instance.results;
    var size = results.length;
    for(var i = 0; i < size; i++) {
      results[i].result.memory_size = DcmgrGUI.Converter.unit(results[i].result.memory_size, 'megabyte');
    }
    return data;
  });

  c_list.detail_filter.add(function(data){
    data.item.memory_size = DcmgrGUI.Converter.unit(data.item.memory_size, 'megabyte');
    return data;
  });

  var bt_refresh  = new DcmgrGUI.Refresh();

  var instance_action_helper = function(action){

    var instances = $(this).find('#instances').find('td.instance_id');
    var ids = [];

    $.each(instances, function() {
      ids.push($(this).text());
    });

    var data = $.param({ids:ids});

    var request = new DcmgrGUI.Request;
    request.post({
      "url": '/instances/'+ action,
      "data": data,
      success: function(json, status) {
       bt_refresh.element.trigger('dcmgrGUI.refresh');
      }
    });

    $(this).dialog("close");
  };

  var bt_instance_start = new DcmgrGUI.Dialog({
    target:'.start_instances',
    width:400,
    height:200,
    title:$.i18n.prop('start_instances_header'),
    path:'/start_instances',
    button:{}
  });
  bt_instance_start.button[$.i18n.prop('close_button')]=function() { $(this).dialog("close"); };
  bt_instance_start.button[$.i18n.prop('start_button')]=function() {
      instance_action_helper.call(this,'start');
  };

  var bt_instance_stop = new DcmgrGUI.Dialog({
     target:'.stop_instances',
     width:400,
     height:200,
     title: $.i18n.prop('stop_instances_header'),
     path:'/stop_instances',
     button:{},
  });
  bt_instance_stop.button[$.i18n.prop('close_button')]=function() { $(this).dialog("close"); };
  bt_instance_stop.button[$.i18n.prop('stop_button')]=function() {
      instance_action_helper.call(this,'stop');
  };

  var instance_reboot_buttons = {};
  instance_reboot_buttons[close_button_name] = function() { $(this).dialog("close"); }
  instance_reboot_buttons[reboot_button_name] = function() {
    instance_action_helper.call(this,'reboot');
  }

  var bt_instance_reboot = new DcmgrGUI.Dialog({
     target:'.reboot_instances',
     width:400,
     height:200,
     title:$.i18n.prop('reboot_instances_header'),
     path:'/reboot_instances',
     button: instance_reboot_buttons
  });

  var instance_terminate_buttons = {};
  instance_terminate_buttons[close_button_name] = function() { $(this).dialog("close"); };
  instance_terminate_buttons[terminate_button_name] = function() {
    instance_action_helper.call(this,'terminate');
  }

  var bt_instance_terminate = new DcmgrGUI.Dialog({
    target:'.terminate_instances',
    width:400,
    height:200,
    title:$.i18n.prop('terminate_instances_header'),
    path:'/terminate_instances',
    button: instance_terminate_buttons
  });

  var instance_backup_buttons = {};
  instance_backup_buttons[close_button_name] = function() { $(this).dialog("close"); }
  instance_backup_buttons[backup_button_name] = function() {
    var instance_id = $(this).find('#instance_id').val();
    var display_name = $(this).find('#backup_display_name').val();
    var description = $(this).find('#backup_description').val();

    var data = ['instance_id='+instance_id,
                'backup_display_name=' + display_name,
                'backup_description=' + description
               ].join('&');

    var request = new DcmgrGUI.Request;
    request.post({
      "url": '/instances/backup',
      "data": data,
      success: function(json, status){
        bt_refresh.element.trigger('dcmgrGUI.refresh');
      }
    });
    $(this).dialog("close");
  }

  var bt_instance_backup = new DcmgrGUI.Dialog({
    target:'.backup_instances',
    width:600,
    height:250,
    title: $.i18n.prop('backup_instances_header'),
    path:'/backup_instances',
    button:instance_backup_buttons
  });

  var instance_poweroff_buttons = {};
  instance_poweroff_buttons[close_button_name] = function() { $(this).dialog("close"); };
  instance_poweroff_buttons[poweroff_button_name] = function() {
    instance_action_helper.call(this,'poweroff');
  }

  var bt_instance_poweroff = new DcmgrGUI.Dialog({
    target:'.poweroff_instances',
    width:400,
    height:200,
    title:$.i18n.prop('poweroff_instances_header'),
    path:'/poweroff_instances',
    button: instance_poweroff_buttons
  });

  var instance_poweron_buttons = {};
  instance_poweron_buttons[close_button_name] = function() { $(this).dialog("close"); };
  instance_poweron_buttons[poweron_button_name] = function() {
    instance_action_helper.call(this,'poweron');
  }

  var bt_instance_poweron = new DcmgrGUI.Dialog({
    target:'.poweron_instances',
    width:400,
    height:200,
    title:$.i18n.prop('poweron_instances_header'),
    path:'/poweron_instances',
    button: instance_poweron_buttons
  });

  bt_refresh.element.bind('dcmgrGUI.refresh',function(){
    c_list.page = c_pagenate.current_page;
    list_request.url = DcmgrGUI.Util.getPagePath('/instances/list/',c_list.page);
    list_request.data = DcmgrGUI.Util.getPagenateData(c_pagenate.start,c_pagenate.row);
    c_list.element.trigger('dcmgrGUI.updateList',{request:list_request})

    //update detail
    $.each(c_list.checked_list,function(check_id,obj){
      $($('#detail').find('#'+check_id)).remove();
      c_list.checked_list[check_id].c_detail.update({
        url:DcmgrGUI.Util.getPagePath('/instances/show/',check_id)
      },true);
    });
  });

  c_pagenate.element.bind('dcmgrGUI.updatePagenate',function(){
    c_list.clearCheckedList();
    $('#detail').html('');
    bt_refresh.element.trigger('dcmgrGUI.refresh');
  });

  var selectmenu = $('#instance_action').selectmenu({
    width: 150,
    menuWidth: 150,
    handleWidth: 26,
    style:'dropdown',
    select: function(event){
      var select_action = $(this).val();
      var selected_ids = c_list.currentMultiChecked();
      var ids = selected_ids['ids'];
      var is_open_poweroff = true;
      var is_open_poweron = true;
      $.each(ids, function(key,uuid){
        var row_id = '#row-'+uuid;
        var state = $(row_id).find('.state').text();
        switch(state){
          case 'running':
            is_open_poweron = false;
            break;
          case 'halted':
            is_open_poweroff = false;
            break;
        }
      });

      switch(select_action) {
        case 'terminate':
          bt_instance_terminate.open(selected_ids);
          break;
        case 'reboot':
          bt_instance_reboot.open(selected_ids);
          break;
        case 'start':
          bt_instance_start.open(selected_ids);
          break;
        case 'stop':
          bt_instance_stop.open(selected_ids);
          break;
        case 'poweroff':
          if(is_open_poweroff){
            bt_instance_poweroff.open(selected_ids);
          }
          break;
        case 'poweron':
          if(is_open_poweron){
            bt_instance_poweron.open(selected_ids);
          }
          break;
      }
    }
  });

  $(bt_refresh.target).button({ disabled: false });
  selectmenu.data('selectmenu').disableButton();
  $(bt_instance_backup.target).button({ disabled: true });
  bt_instance_backup.target.bind('click', function() {
    if(!bt_instance_backup.is_disabled()) {
      var selected_ids = c_list.getCheckedInstanceIds();
      if( selected_ids ){
        bt_instance_backup.open(selected_ids);
      } else {
        $(this).button({ disabled: true });
      }
    }
    return false;
  });

  var actions = {};
  actions.changeButtonState = function() {
    var ids = c_list.currentMultiChecked()['ids'];
    var flag = true;
    var is_selectmenu = false;
    var is_instance_backup = false;
    $.each(ids, function(key, uuid){
      var row_id = '#row-'+uuid;
      var state = $(row_id).find('.state').text();
      is_selectmenu = _.include(['running', 'stopped', 'halted'], state)
      is_instance_backup = _.include(['halted'], state)
      flag = _.contains([is_selectmenu, is_instance_backup], true)
    });

    if (flag){
      if(is_selectmenu) {
        selectmenu.data('selectmenu').enableButton();
      } else {
        selectmenu.data('selectmenu').disableButton();
      }

      if(is_instance_backup) {
        bt_instance_backup.enableDialogButton();
      } else {
        bt_instance_backup.disableDialogButton();
      }

    } else{
      selectmenu.data('selectmenu').disableButton();
      bt_instance_backup.disableDialogButton();
    }
  }

  dcmgrGUI.notification.subscribe('checked_box', actions, 'changeButtonState');
  dcmgrGUI.notification.subscribe('unchecked_box', actions, 'changeButtonState');
  dcmgrGUI.notification.subscribe('change_pagenate', selectmenu.data('selectmenu'), 'disableButton');
  dcmgrGUI.notification.subscribe('change_pagenate', bt_instance_backup, 'disableDialogButton');
  //list
  c_list.setData(null);
  c_list.update(list_request,true);
}
