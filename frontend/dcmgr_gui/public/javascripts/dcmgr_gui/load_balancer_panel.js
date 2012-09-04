DcmgrGUI.prototype.loadBalancerPanel = function(){
  var total = 0;
  var maxrow = 10;
  var page = 1;
  var list_request = {
    "url" : DcmgrGUI.Util.getPagePath('/load_balancers/list/',page),
    "data" : DcmgrGUI.Util.getPagenateData(page,maxrow)
  };

  DcmgrGUI.List.prototype.getEmptyData = function(){
    return [{}]
  }

  DcmgrGUI.Detail.prototype.getEmptyData = function(){
    return {}
  }

  var c_pagenate = new DcmgrGUI.Pagenate({
    row:maxrow,
    total:total
  });

  var c_list = new DcmgrGUI.List({
    element_id:'#display_load_balancers',
    template_id:'#loadBalancersListTemplate',
    maxrow:maxrow,
    page:page
  });

  var close_button_name = $.i18n.prop('close_button');
  var create_button_name = $.i18n.prop('create_button');
  var delete_button_name = $.i18n.prop('delete_load_balancer_button');
  var register_button_name = $.i18n.prop('register_button');
  var unregister_button_name = $.i18n.prop('unregister_button');
  var poweron_button_name =$.i18n.prop('poweron_button');
  var poweroff_button_name =$.i18n.prop('poweroff_button');
  var update_button_name =$.i18n.prop('update_button');
  var change_instance_protocol = function(e) {
    var load_balancer_protocol = $(e).find('#load_balancer_protocol');
    var instance_protocol = $(e).find('#instance_protocol');
    load_balancer_protocol.change(function() {
      if(_.include(['http', 'https'], load_balancer_protocol.val())) {
        instance_protocol.html('http');
      } else if(_.include(['ssl', 'tcp'], load_balancer_protocol.val())) {
        instance_protocol.html('tcp');
      }
    });
    load_balancer_protocol.trigger('change');
  };

  c_list.setDetailTemplate({
    template_id:'#loadBalancersDetailTemplate',
    detail_path:'/load_balancers/show/'
  });

  c_list.element.bind('dcmgrGUI.contentChange',function(event,params){
    var load_balancer = params.data.load_balancer;
    c_pagenate.changeTotal(load_balancer.total);
    c_list.setData(load_balancer.results);
    c_list.singleCheckList(c_list.detail_template);

    var edit_load_balancer_buttons = {};
    edit_load_balancer_buttons[close_button_name] = function() { $(this).dialog("close"); };
    edit_load_balancer_buttons[update_button_name] = function(event) {
      var load_balancer_id = c_list.currentChecked();
      var display_name = $(this).find('#display_name').val();
      var description = $(this).find('#description').val();
      var load_balancer_protocol = $(this).find('#load_balancer_protocol').val();
      var load_balancer_port = $(this).find('#load_balancer_port').val();
      var instance_protocol = $(this).find('#instance_protocol').text();
      var instance_port = $(this).find('#instance_port').val();
      var public_key = encodeURIComponent($(this).find('#public_key').val());
      var private_key = encodeURIComponent($(this).find('#private_key').val());
      var balance_algorithm = $(this).find('input[name="balance_algorithm"]:checked').val();
      var certificate_chain = encodeURIComponent($(this).find('#certificate_chain').val());
      var cookie_name = $(this).find('#cookie_name').val();
      var data = "display_name="+display_name
                 +"&description="+description
                 +"&load_balancer_protocol="+load_balancer_protocol
                 +"&load_balancer_port="+load_balancer_port
                 +"&instance_protocol="+instance_protocol
                 +"&instance_port="+instance_port
                 +"&balance_algorithm="+balance_algorithm
                 +"&private_key="+private_key
                 +"&public_key="+public_key
                 +"&certificate_chain="+certificate_chain
                 +"&cookie_name="+cookie_name;
      var request = new DcmgrGUI.Request;
      request.put({
        "url": '/load_balancers/'+ load_balancer_id +'.json',
        "data": data,
        success: function(json, status){
          bt_refresh.element.trigger('dcmgrGUI.refresh');
        }
      });
      $(this).dialog("close");
    }

    var bt_edit_load_balancer = new DcmgrGUI.Dialog({
      target:'.edit_load_balancer',
      width:600,
      height:430,
      title:$.i18n.prop('edit_load_balancer_header'),
      path:'/edit_load_balancer',
      button: edit_load_balancer_buttons,
      callback: function(){
        change_instance_protocol(this);
      }
    });

    bt_edit_load_balancer.target.bind('click',function(event){
      var uuid = $(this).attr('id').replace(/edit_(lb-[a-z0-9]+)/,'$1');
      if( uuid ){
        bt_edit_load_balancer.open({"ids":[uuid]});
      }
      c_list.checkRadioButton(uuid);
    });

    $(bt_edit_load_balancer.target).button({ disabled: false });

  });

  var bt_refresh  = new DcmgrGUI.Refresh();

  var create_load_balancer_buttons = {};
  create_load_balancer_buttons[close_button_name] = function() { $(this).dialog("close"); };
  create_load_balancer_buttons[create_button_name] = function() {
    var display_name = $(this).find('#display_name').val();
    var description = $(this).find('#description').val();
    var load_balancer_protocol = $(this).find('#load_balancer_protocol').val();
    var load_balancer_port = $(this).find('#load_balancer_port').val();
    var instance_protocol = $(this).find('#instance_protocol').text();
    var instance_port = $(this).find('#instance_port').val();
    var public_key = encodeURIComponent($(this).find('#public_key').val());
    var private_key = encodeURIComponent($(this).find('#private_key').val());
    var balance_algorithm = $(this).find('input[name="balance_algorithm"]:checked').val();
    var certificate_chain = encodeURIComponent($(this).find('#certificate_chain').val());
    var cookie_name = $(this).find('#cookie_name').val();
    var data = "display_name="+display_name
               +"&description="+description
               +"&load_balancer_protocol="+load_balancer_protocol
               +"&load_balancer_port="+load_balancer_port
               +"&instance_protocol="+instance_protocol
               +"&instance_port="+instance_port
               +"&balance_algorithm="+balance_algorithm
               +"&private_key="+private_key
               +"&public_key="+public_key
               +"&certificate_chain="+certificate_chain
               +"&cookie_name="+cookie_name;
    var request = new DcmgrGUI.Request;
    request.post({
      "url": '/load_balancers',
      "data": data,
      success: function(json,status){
        bt_refresh.element.trigger('dcmgrGUI.refresh');
      }
    });

    $(this).dialog("close");
  }

  var bt_create_load_balancer = new DcmgrGUI.Dialog({
    target:'.create_load_balancer',
    width:600,
    height:430,
    title:$.i18n.prop('create_load_balancer_header'),
    path:'/create_load_balancer',
    callback: function(){
      change_instance_protocol(this);
      bt_create_load_balancer.disabledButton(1, false);
   },
    button: create_load_balancer_buttons
  });

  var delete_load_balancer_buttons = {};
  delete_load_balancer_buttons[close_button_name] = function() { $(this).dialog("close"); };
  delete_load_balancer_buttons[delete_button_name] = function() {
    var load_balancer_id = $(this).find('#load_balancer_id').val();
    var request = new DcmgrGUI.Request;
    request.del({
      "url": '/load_balancers/' + load_balancer_id + '.json',
      success: function(json,status){
        bt_refresh.element.trigger('dcmgrGUI.refresh');
      }
    });

    $(this).dialog("close");
  }

  var bt_delete_load_balancer = new DcmgrGUI.Dialog({
    target:'.delete_load_balancer',
    width:400,
    height:210,
    title:$.i18n.prop('delete_load_balancer_header'),
    path:'/delete_load_balancer',
    button: delete_load_balancer_buttons
  });

  var register_load_balancer_buttons = {};
  register_load_balancer_buttons[close_button_name] = function() { $(this).dialog("close"); };
  register_load_balancer_buttons[register_button_name] = function() {
    var load_balancer_id = c_list.currentChecked();
    var register_instances  = $(this).find('#right_select_list').find('option');
    var vifs = [];

    $.each(register_instances,function(i){
      vifs.push("vifs[]="+ $(this).val());
    });

    var data = 'load_balancer_id='+load_balancer_id
               +"&" + vifs.join('&');

    var request = new DcmgrGUI.Request;
    request.put({
      "url": '/load_balancers/register_instances',
      "data": data,
      success: function(json,status){
        bt_refresh.element.trigger('dcmgrGUI.refresh');
      }
    });

    $(this).dialog("close");
  }

  var bt_register_load_balancer = new DcmgrGUI.Dialog({
    target:'.register_load_balancer',
    width:583,
    height:380,
    title:$.i18n.prop('register_load_balancer_header'),
    path:'/register_load_balancer',
    callback: function(){

      var self = this;
      var load_balancer_id = c_list.currentChecked();

      var ready = function(data) {
        if(data['vifs'] == true) {
          bt_register_load_balancer.disabledButton(1, false);
        } else {
          bt_register_load_balancer.disabledButton(1, true);
        }
      }

      var is_ready = {
        'vifs' : false
      }

      bt_register_load_balancer.disabledButton(1, true);

      var request = new DcmgrGUI.Request;
      parallel({
        load_balancer: request.get({
          "url": '/load_balancers/show/' + load_balancer_id + '.json',
           success: function(json, status) {
         }
        }),
        instances: request.get({
          "url": '/instances/all.json',
          success: function(json, status) {
            var data = [];
            var results = json.instance.results;
            var size = results.length;
            for (var i=0; i < size ; i++) {
              if(results[i].result.vif.length > 0) {
                var vif_id = results[i].result.vif[0].vif.vif_id;
                data.push({
                 'value' : vif_id,
                 'name': results[i].result.id
                });
              }
            }

            var load_balancers = new DcmgrGUI.ItemSelector({
               'left_select_id' : '#left_select_list',
               'right_select_id' : '#right_select_list',
               'data' : data,
               'target' : self
             });

             var on_ready = function(size){
               if(size > 0) {
                 is_ready['vifs'] = true;
                 ready(is_ready);
               } else {
                 is_ready['vifs'] = false;
                 ready(is_ready);
               }
             }

             $(self).find('#right_button').click(function(){
               load_balancers.leftToRight();
               on_ready(load_balancers.getRightSelectionCount());
             });

             $(self).find('#left_button').click(function(){
               load_balancers.rightToLeft();
               on_ready(load_balancers.getRightSelectionCount());
             });
         }
        })
        }).next(function(results) {
          $("#left_select_list").unmask();
      });
    },
    button: register_load_balancer_buttons
  });

  var unregister_load_balancer_buttons = {};
  unregister_load_balancer_buttons[close_button_name] = function() { $(this).dialog("close"); };
  unregister_load_balancer_buttons[unregister_button_name] = function() {
    var load_balancer_id = c_list.currentChecked();
    var unregister_instances  = $(this).find('#right_select_list').find('option');
    var vifs = [];

    $.each(unregister_instances,function(i){
      vifs.push("vifs[]="+ $(this).val());
    });

    var data = 'load_balancer_id='+load_balancer_id
               +"&" + vifs.join('&');

    var request = new DcmgrGUI.Request;
    request.put({
      "url": '/load_balancers/unregister_instances',
      "data": data,
      success: function(json,status){
        bt_refresh.element.trigger('dcmgrGUI.refresh');
      }
    });

    $(this).dialog("close");
  }

  var bt_unregister_load_balancer = new DcmgrGUI.Dialog({
    target:'.unregister_load_balancer',
    width:583,
    height:380,
    title:$.i18n.prop('unregister_load_balancer_header'),
    path:'/unregister_load_balancer',
    callback: function(){

      var self = this;
      var load_balancer_id = c_list.currentChecked();

      var ready = function(data) {
        if(data['vifs'] == true) {
          bt_unregister_load_balancer.disabledButton(1, false);
        } else {
          bt_unregister_load_balancer.disabledButton(1, true);
        }
      }

      var is_ready = {
        'vifs' : false
      }

      bt_unregister_load_balancer.disabledButton(1, true);

      var request = new DcmgrGUI.Request;
      parallel({
        load_balancer: request.get({
          "url": '/load_balancers/show/' + load_balancer_id + '.json',
           success: function(json, status) {
         }
        }),
        instances: request.get({
          "url": '/instances/all.json',
          success: function(json, status) {
            var data = [];
            var results = json.instance.results;
            var size = results.length;
            for (var i=0; i < size ; i++) {
              if(results[i].result.vif.length > 0) {
                var vif_id = results[i].result.vif[0].vif.vif_id;
                data.push({
                 'value' : vif_id,
                 'name': results[i].result.id
                });
              }
            }

            var load_balancers = new DcmgrGUI.ItemSelector({
               'left_select_id' : '#left_select_list',
               'right_select_id' : '#right_select_list',
               'data' : data,
               'target' : self
             });

             var on_ready = function(size){
               if(size > 0) {
                 is_ready['vifs'] = true;
                 ready(is_ready);
               } else {
                 is_ready['vifs'] = false;
                 ready(is_ready);
               }
             }

             $(self).find('#right_button').click(function(){
               load_balancers.leftToRight();
               on_ready(load_balancers.getRightSelectionCount());
             });

             $(self).find('#left_button').click(function(){
               load_balancers.rightToLeft();
               on_ready(load_balancers.getRightSelectionCount());
             });
         }
        })
        }).next(function(results) {
          $("#left_select_list").unmask();
      });
    },
    button: unregister_load_balancer_buttons
  });

  var load_balancers_poweron_buttons = {};
  load_balancers_poweron_buttons[close_button_name] = function() { $(this).dialog("close"); };
  load_balancers_poweron_buttons[poweron_button_name] = function() {
    var load_balancer_id = c_list.currentChecked();
    var request = new DcmgrGUI.Request;
    request.put({
      "url": "/load_balancers/poweron/" + load_balancer_id,
      success: function(json,status){
        bt_refresh.element.trigger('dcmgrGUI.refresh');
      }
    });

    $(this).dialog("close");
  }

  var bt_poweron_instance = new DcmgrGUI.Dialog({
    target:'.poweron_load_balancer',
    width:400,
    height:200,
    title:$.i18n.prop('poweron_load_balancer_header'),
    path:'/poweron_load_balancer',
    button: load_balancers_poweron_buttons
  });

  var load_balancers_poweroff_buttons = {};
  load_balancers_poweroff_buttons[close_button_name] = function() { $(this).dialog("close"); };
  load_balancers_poweroff_buttons[poweroff_button_name] = function() {
    var load_balancer_id = c_list.currentChecked();
    var request = new DcmgrGUI.Request;
    request.put({
      "url": "/load_balancers/poweroff/" + load_balancer_id,
      success: function(json,status){
        bt_refresh.element.trigger('dcmgrGUI.refresh');
      }
    });

    $(this).dialog("close");
  }

  var bt_poweroff_load_balancer = new DcmgrGUI.Dialog({
    target:'.poweroff_load_balancer',
    width:400,
    height:200,
    title:$.i18n.prop('poweroff_load_balancer_header'),
    path:'/poweroff_load_balancer',
    button: load_balancers_poweroff_buttons
  });

  bt_refresh.element.bind('dcmgrGUI.refresh',function(){
    c_list.page = c_pagenate.current_page;
    list_request.url = DcmgrGUI.Util.getPagePath('/load_balancers/list/',c_list.page);
    list_request.data = DcmgrGUI.Util.getPagenateData(c_pagenate.start,c_pagenate.row);
    c_list.element.trigger('dcmgrGUI.updateList',{request:list_request})

    var check_id = c_list.currentChecked();
    //remove detail element
    $($('#detail').find('#'+check_id)).remove();
  });

  bt_create_load_balancer.target.bind('click',function(){
    bt_create_load_balancer.open();
  });

  c_pagenate.element.bind('dcmgrGUI.updatePagenate',function(){
    c_list.clearCheckedList();
    $('#detail').html('');
    bt_refresh.element.trigger('dcmgrGUI.refresh');
  });

  var selectmenu = $('#load_balancer_action').selectmenu({
    width: 150,
    menuWidth: 150,
    handleWidth: 26,
    style:'dropdown',
    select: function(event){
      var select_action = $(this).val()
      var selected_id = c_list.currentChecked();
      switch(select_action) {
        case 'register':
          bt_register_load_balancer.open({ids: [selected_id]});
          break;
        case 'unregister':
          bt_unregister_load_balancer.open({ids: [selected_id]});
          break;
        case 'delete':
          bt_delete_load_balancer.open({ids: [selected_id]});
          break;
        case 'poweron':
          bt_poweron_instance.open({ids: [selected_id]});
          break;
        case 'poweroff':
          bt_poweroff_load_balancer.open({ids: [selected_id]});
          break;
      }
    }
  });

  selectmenu.data('selectmenu').disableButton();

  $(bt_create_load_balancer.target).button({ disabled: false });
  $(bt_refresh.target).button({ disabled: false });

  var actions = {};
  actions.changeButtonState = function() {
    var uuid = c_list.currentChecked();
    var row_id = '#row-'+uuid;
    var state = $(row_id).find('.state').text();

    if(_.include(['running', 'halted'], state)) {
      selectmenu.data('selectmenu').enableButton();
    } else {
      selectmenu.data('selectmenu').disableButton();
    }
  }

  dcmgrGUI.notification.subscribe('checked_radio', actions, 'changeButtonState');

  //list
  c_list.setData(null);
  c_list.update(list_request,true);
}
