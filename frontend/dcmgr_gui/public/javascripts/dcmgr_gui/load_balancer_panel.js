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
  var change_button_behavior = function(e, button) {
      var self = e;
      var is_ready = {
	  'display_name':false,
	  'load_balancer_port':false,
	  'instance_port':false,
	  'cookie_name':true,
	  'private_key':true,
	  'public_key':true
      };
      var ready = function(data) {
	  if(data['display_name'] == true &&
	     data['load_balancer_port'] == true &&
	     data['instance_port'] == true &&
	     data['cookie_name'] == true &&
	     data['private_key'] == true &&
	     data['public_key'] == true) {
	      button.disabledButton(1, false);
	  } else {
	      button.disabledButton(1, true);
	  }
      }
      var display_name_params = {'name': 'display_name', 'is_ready': is_ready, 'ready': ready};
      $(e).find('#display_name').bind('keyup', display_name_params, DcmgrGUI.Util.checkTextField);
      $(e).find('#display_name').bind('paste', display_name_params, DcmgrGUI.Util.checkTextField);
      $(e).find('#display_name').bind('cut', display_name_params, DcmgrGUI.Util.checkTextField);

      var load_balancer_port_params = {'name': 'load_balancer_port', 'is_ready': is_ready, 'ready': ready};
      $(e).find('#load_balancer_port').bind('keyup', load_balancer_port_params, DcmgrGUI.Util.checkTextField);
      $(e).find('#load_balancer_port').bind('paste', load_balancer_port_params, DcmgrGUI.Util.checkTextField);
      $(e).find('#load_balancer_port').bind('cut', load_balancer_port_params, DcmgrGUI.Util.checkTextField);

      var instance_port_params = {'name': 'instance_port', 'is_ready': is_ready, 'ready': ready};
      $(e).find('#instance_port').bind('keyup', instance_port_params, DcmgrGUI.Util.checkTextField);
      $(e).find('#instance_port').bind('paste', instance_port_params, DcmgrGUI.Util.checkTextField);
      $(e).find('#instance_port').bind('cut', instance_port_params, DcmgrGUI.Util.checkTextField);

      var cookie_name_params = {'name': 'cookie_name', 'is_ready': is_ready, 'ready': ready};
      $(e).find('#cookie_name').bind('keyup', cookie_name_params, DcmgrGUI.Util.checkTextField);
      $(e).find('#cookie_name').bind('paste', cookie_name_params, DcmgrGUI.Util.checkTextField);
      $(e).find('#cookie_name').bind('cut', cookie_name_params, DcmgrGUI.Util.checkTextField);

      var public_key_params = {'name': 'public_key', 'is_ready': is_ready, 'ready': ready};
      $(e).find('#public_key').bind('keyup', public_key_params, DcmgrGUI.Util.checkTextField);
      $(e).find('#public_key').bind('paste', public_key_params, DcmgrGUI.Util.checkTextField);
      $(e).find('#public_key').bind('cut', public_key_params, DcmgrGUI.Util.checkTextField);

      var private_key_params = {'name': 'private_key', 'is_ready': is_ready, 'ready': ready};
      $(e).find('#private_key').bind('keyup', private_key_params, DcmgrGUI.Util.checkTextField);
      $(e).find('#private_key').bind('paste', private_key_params, DcmgrGUI.Util.checkTextField);
      $(e).find('#private_key').bind('cut', private_key_params, DcmgrGUI.Util.checkTextField);
      $(e).find('input[name="balance_algorithm"]').bind('change', function(){
	      if ($(this).is(':checked')) {
		  if($(this).val() == "leastconn") {
		      $(self).find('#use_sticky_session').removeAttr("disabled");
		  } else {
		      $(self).find('#use_sticky_session').attr("disabled", "disabled");
		      $(self).find('#use_sticky_session').attr("checked", false);
		      $(self).find('#cookie_name').attr("disabled", "disabled");
		      $(self).find('#cookie_name').val("");
		      is_ready['cookie_name'] = true;
		      ready(is_ready);
		  }
	      }
	  }).change();
      $(e).find('#use_sticky_session').bind('change', function(){
	      if ($(this).is(':checked')) {
		  $(self).find('#cookie_name').removeAttr("disabled");
		  if ($(self).find('#cookie_name').val()) {
		      is_ready['cookie_name'] = true;
		      ready(is_ready);
		  } else {
		      is_ready['cookie_name'] = false;
		      ready(is_ready);
		  }
	      } else {
		  $(self).find('#cookie_name').attr("disabled", "disabled");
		  $(self).find('#cookie_name').val("");
		  is_ready['cookie_name'] = true;
		  ready(is_ready);
	      }
	  }).change();
      $(e).find('#load_balancer_protocol').bind('change', function(){
	      if(_.include(['http','tcp'], $(this).val())) {
		  $(self).find('#private_key').attr("disabled", "disabled");
		  $(self).find('#public_key').attr("disabled", "disabled");
		  $(self).find('#private_key').val("");
		  $(self).find('#public_key').val("");
		  is_ready['private_key'] = true;
		  is_ready['public_key'] = true;
		  ready(is_ready);
	      } else {
		  $(self).find('#private_key').removeAttr("disabled");
		  $(self).find('#public_key').removeAttr("disabled");
		  if ( $(self).find('#private_key').val() && $(self).find('#public_key').val()) {
		  is_ready['private_key'] = true;
		  is_ready['public_key'] = true;
		  } else {
		  is_ready['private_key'] = false;
		  is_ready['public_key'] = false;
		  }
		  ready(is_ready);
	      }
	  }).change();
      $(e).find('#display_name').bind('change', display_name_params, DcmgrGUI.Util.checkTextField).change();
      $(e).find('#load_balancer_port').bind('change', load_balancer_port_params, DcmgrGUI.Util.checkTextField).change();
      $(e).find('#instance_port').bind('change', instance_port_params, DcmgrGUI.Util.checkTextField).change();
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
	change_button_behavior(this, bt_edit_load_balancer);
      }
    });

    bt_edit_load_balancer.target.bind('click',function(event){
      var uuid = $(this).attr('id').replace(/edit_(lb-[a-z0-9]+)/,'$1');
      var row_id = '#row-'+uuid;
      var state = $(row_id).find('.state').text();
      if(uuid && state == 'running' ){
        bt_edit_load_balancer.open({"ids":[uuid]});
	bt_edit_load_balancer.disabledButton(1, true);
      }
      c_list.checkRadioButton(uuid);
    });

    c_list.element.find(".edit_load_balancer").each(function(key, value){
      var uuid = $(value).attr('id').replace(/edit_(lb-[a-z0-9]+)/,'$1');
      var row_id = '#row-'+uuid;
      var state = $(row_id).find('.state').text();
      if(uuid && state == 'running') {
        $(this).button({ disabled: false });
      } else {
        $(this).button({ disabled: true });
      }
    });

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
      change_button_behavior(this, bt_create_load_balancer);
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
    height:480,
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
          }
        })
        }).next(function(json) {
          var data = [];
          var registered_instances = [];

          $.each(json.load_balancer.target_vifs, function(k, v){
            registered_instances.push(v.instance_id);
          });

          var registerable_instances = _.reject(json.instances.instance.results, function(i){
            return _.include(registered_instances, i.result.id)
          });

          $.each(registerable_instances, function(idx, instance) {
            if(instance.result.vif.length > 0) {
              var vif_id = instance.result.vif[0].vif.vif_id;
              data.push({
               'value' : vif_id,
               'name': instance.result.id
              });
            }
          });

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

          $(self).find("#left_select_list").unmask();
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
    height:480,
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
          }
        })
        }).next(function(json) {
          var data = [];
          var registered_instances = [];

          $.each(json.load_balancer.target_vifs, function(k, v){
            registered_instances.push(v.instance_id);
          });

          var unregister_instances = _.filter(json.instances.instance.results, function(i){
            return _.include(registered_instances, i.result.id)
          });

          $.each(unregister_instances, function(idx, instance) {
            if(instance.result.vif.length > 0) {
            var vif_id = instance.result.vif[0].vif.vif_id;
              data.push({
               'value' : vif_id,
               'name': instance.result.id
              });
            }
          });

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

          $(self).find("#left_select_list").unmask();
      })
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

  var load_balancers_active_standby_buttons = {};
  load_balancers_active_standby_buttons[close_button_name] = function() { $(this).dialog("close"); };
  load_balancers_active_standby_buttons[update_button_name] = function(e) {
    var load_balancer_id = c_list.currentChecked();
    var self = this;
    var target_vifs = [];

    $.each($(this).find('#list').find(':checked'), function(k, v) {
      var id = '#row_' + k;
      var network_vif_id = $($(self).find(id).children()[4]).attr('title');
      var selected_mode = $(v).attr('class');
      if(selected_mode == 'active') {
        var fallback_mode = 'off';
      } else if(selected_mode == 'standby') {
        var fallback_mode = 'on';
      }

      target_vifs.push('target_vifs[][network_vif_id]=' + network_vif_id);
      target_vifs.push('target_vifs[][fallback_mode]=' + fallback_mode);
    });

    var data = target_vifs.join('&');
    var request = new DcmgrGUI.Request;
    request.put({
      "url": '/load_balancers/'+ load_balancer_id +'.json',
      data: data,
      success: function(json,status){
        bt_refresh.element.trigger('dcmgrGUI.refresh');
      }
    });

    $(this).dialog("close");
  }

  var bt_active_standby_load_balancer = new DcmgrGUI.Dialog({
    target:'.active_standby_load_balancer',
    width:600,
    height:480,
    title:$.i18n.prop('active_standby_load_balancer_header'),
    path:'/active_standby_load_balancer',
    callback: function(e) {
      var load_balancer_id = c_list.currentChecked();
      var self = this;

      function radioFormatter(cellvalue, options, rowObject) {
        var radioName = "radio" + rowObject.id;
        var checked = '';
        var name = 'instance_' + options.rowId;
        var active = 2;
        var standby = 3;

        if(options.pos == active) {
          var class_name = 'active';
        }

        if(options.pos == standby){
          var class_name = 'standby';
        }

        if((options.pos == active || options.pos == standby) && cellvalue == 1) {
          checked = 'checked';
        }

        return "<input class='"+ class_name +"' name='"+name+"' type='radio' name='" + radioName + "' value='" + cellvalue + "'"+checked+"/>";
      };

      $(this).find("#list").jqGrid({
        datatype: function(postdata) {
          var request = new DcmgrGUI.Request;
          request.get({
            "url": '/load_balancers/show/' + load_balancer_id + '.json',
            success: function(json,status) {
              tv = json.target_vifs;
              target_vifs = [];
              _.each(tv, function(vif){
                if(vif.fallback_mode == 'on') {
                  var active = 0;
                  var standby = 1;
                } else if (vif.fallback_mode == 'off') {
                  var active = 1;
                  var standby = 0;
                }

                target_vifs.push({
                  'display_name': vif.display_name,
                  'instance_id': vif.instance_id,
                  'active': active,
                  'standby': standby,
                  'network_vif_id': vif.network_vif_id
                });

              });

              $(self).find("#list").clearGridData(true);
              for(var i=0;i<=target_vifs.length;i++){
                var id = 'row_' + i;
                $(self).find("#list").jqGrid('addRowData',id,target_vifs[i]);
              }

             }
           })
        },
        altRows: true,
        colNames:[$.i18n.prop('active_standby_load_balancer_instance_id'),
                  $.i18n.prop('active_standby_load_balancer_instance_name'),
                  $.i18n.prop('active_standby_load_balancer_active'),
                  $.i18n.prop('active_standby_load_balancer_standby'),
                  $.i18n.prop('active_standby_load_balancer_network_vif_id')
                 ],
        colModel:[
          {name:'instance_id',align:'center',sortable:false,width:167},
          {name:'display_name',align:'center',sortable:false,width:167},
          {name:'active',align:'center',editable:true, editrules: {required:true}, edittype:'custom', formatter:radioFormatter, sortable:false,width:100},
          {name:'standby',align:'center',editable:true, editrules: {required:true}, edittype:'custom', formatter:radioFormatter, sortable:false,width:100},
          {name:'network_vif_id', hidden:true}
        ],
        rowNum:10,
        height:'240px',
        width:'460px',
        pager:'#pager1',
        autowidth: true,
        shrinkToFit: false,
       })
    },
    button: load_balancers_active_standby_buttons
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
    bt_create_load_balancer.disabledButton(1, true);
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
      var row_id = '#row-'+selected_id;
      var state = $(row_id).find('.state').text();

      switch(select_action) {
        case 'register':
          if (state == 'running') {
            bt_register_load_balancer.open({ids: [selected_id]});
          }
          break;
        case 'unregister':
          if (state == 'running') {
            bt_unregister_load_balancer.open({ids: [selected_id]});
          }
          break;
        case 'delete':
          bt_delete_load_balancer.open({ids: [selected_id]});
          break;
        case 'poweron':
          if (state == 'halted') {
            bt_poweron_instance.open({ids: [selected_id]});
          }
          break;
        case 'poweroff':
          if (state == 'running') {
            bt_poweroff_load_balancer.open({ids: [selected_id]});
          }
          break;
        case 'active_standby':
          if (state == 'running') {
            bt_active_standby_load_balancer.open({ids: [selected_id]});
          }
          break;
      }
    }
  });

  selectmenu.data('selectmenu').disableButton();

  $(bt_create_load_balancer.target).button({ disabled: false });
  $(bt_delete_load_balancer.target).button({ disabled: true });
  $(bt_refresh.target).button({ disabled: false });

  var actions = {};
  actions.changeButtonState = function() {
    var uuid = c_list.currentChecked();
    var row_id = '#row-'+uuid;
    var state = $(row_id).find('.state').text();
    if(_.include(['running', 'halted'], state)) {
      bt_delete_load_balancer.enableDialogButton();
      selectmenu.data('selectmenu').enableButton();
    }else {
      bt_delete_load_balancer.disableDialogButton();
      selectmenu.data('selectmenu').disableButton();
    }
  }

  dcmgrGUI.notification.subscribe('checked_radio', actions, 'changeButtonState');

  //list
  c_list.setData(null);
  c_list.update(list_request,true);
}
