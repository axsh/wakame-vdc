DcmgrGUI.prototype.imagePanel = function(){
  var total = 0;
  var maxrow = 10;
  var page = 1;
  var list_request = { 
    "url":DcmgrGUI.Util.getPagePath('/machine_images/list/',page),
    "data" : DcmgrGUI.Util.getPagenateData(page,maxrow)
  }
  
  DcmgrGUI.List.prototype.getEmptyData = function(){
    return [{
      "id":'',
      "wmi_id":'',
      "source":'',
      "owner":'',
      "visibility":'',
      "state":''
    }]
  }
  
  DcmgrGUI.Detail.prototype.getEmptyData = function(){
        return {
            "name" : "-",
            "description" : "-",
            "source" : "-",
            "owner" : "-",
            "visibility" : "-",
            "product_code" : "-",
            "state" : "-",
            "karnel_id":"-",
            "platform" : "-",
            "root_device_type":"-",
            "root_device":"-",
            "image_size":"-",
            "block_devices":"-",
            "virtualization":"",
            "state_reason":"-"
          }
      }
  
  var close_button_name = $.i18n.prop('close_button'); 
  var launch_button_name = $.i18n.prop('launch_button');
  var update_button_name = $.i18n.prop('update_button');
  var delete_button_name = $.i18n.prop('delete_button');

  var c_pagenate = new DcmgrGUI.Pagenate({
    row:maxrow,
    total:total
  });
  
  var c_list = new DcmgrGUI.List({
    element_id:'#display_images',
    template_id:'#imagesListTemplate',
    maxrow:maxrow,
    page:page
  });
      
  c_list.setDetailTemplate({
    template_id:'#imagesDetailTemplate',
    detail_path:'/machine_images/show/'
  });
  
  c_list.element.bind('dcmgrGUI.contentChange',function(event,params){
    var image = params.data.image;
    c_pagenate.changeTotal(image.total);
    c_list.setData(image.results);
    c_list.singleCheckList(c_list.detail_template);
    c_list.element.find(".edit_machine_image").each(function(key,value){
      $(this).button({ disabled: false });
      var uuid = $(value).attr('id').replace(/edit_(wmi-[a-z0-9]+)/,'$1');
      var row_id = '#row-'+uuid;
      var owner = $('#mainarea_wide').find('#owner').val();
      var image_owner = $(row_id).find('.owner').text();
      if( uuid && owner == image_owner){
	$(this).bind('click',function(){
	  bt_edit_machine_image.open({"ids":[uuid]});
	});
      } else {
	  $(this).button({ disabled: true});
      }
    });

    var edit_machine_image_buttons = {};
    edit_machine_image_buttons[close_button_name] = function() { $(this).dialog("close"); };
    edit_machine_image_buttons[update_button_name] = function(event) {
      var image_id = $(this).find('#image_id').val();
      var display_name = $(this).find('#machine_image_display_name').val();
      var description = $(this).find('#machine_image_description').val();
      var data = 'display_name=' + display_name
                +'&description=' + description;

      var request = new DcmgrGUI.Request;
      request.put({
        "url": '/machine_images/'+ image_id +'.json',
        "data": data,
        success: function(json, status){
          bt_refresh.element.trigger('dcmgrGUI.refresh');
        }
      });
      $(this).dialog("close");
    }

    var bt_edit_machine_image = new DcmgrGUI.Dialog({
      target:'.edit_machine_image',
      width:500,
      height:250,
      title:$.i18n.prop('edit_machine_image_header'),
      path:'/edit_machine_image',
      button: edit_machine_image_buttons,
      callback: function(){
        var params = { 'button': bt_edit_machine_image, 'element_id': 1 };
        $(this).find('#machine_image_display_name').bind('paste', params, DcmgrGUI.Util.availableTextField);
        $(this).find('#machine_image_display_name').bind('keyup', params, DcmgrGUI.Util.availableTextField);
      }
    });
  });
  
  var bt_refresh  = new DcmgrGUI.Refresh();
  
  bt_refresh.element.bind('dcmgrGUI.refresh',function(){
    c_list.page = c_pagenate.current_page;
    list_request.url = DcmgrGUI.Util.getPagePath('/machine_images/list/',c_pagenate.current_page);
    list_request.data = DcmgrGUI.Util.getPagenateData(c_pagenate.start,c_pagenate.row);
    c_list.element.trigger('dcmgrGUI.updateList',{request:list_request})
    
    var check_id = c_list.currentChecked();
    //remove detail element
    $($('#detail').find('#'+check_id)).remove();
    //disable dialog button
    bt_launch_instance.disableDialogButton();
    bt_delete_backup_image.disableDialogButton();
  });
  
  c_pagenate.element.bind('dcmgrGUI.updatePagenate',function(){
    c_list.clearCheckedList();
    $('#detail').html('');
    bt_refresh.element.trigger('dcmgrGUI.refresh');
  });
  
  var launch_instance_buttons = {};
  launch_instance_buttons[close_button_name] = function() { $(this).dialog("close"); };  
  launch_instance_buttons[launch_button_name] = function() {
    var image_id = $(this).find('#image_id').val();
    var display_name = $(this).find('#display_name').val();
    var host_name = $(this).find('#host_name').val();
    var instance_spec_id = $(this).find('#instance_specs').val();
    var ssh_key_pair = $(this).find('#ssh_key_pair').find('option:selected').text();
    var launch_in = $(this).find('#right_select_list').find('option');
    var user_data = $(this).find('#user_data').val();
    var security_groups = [];
    $.each(launch_in,function(i){
     security_groups.push("security_groups[]="+ $(this).text());
    });
    var vifs = [];
    for (var i=0; i < 5 ; i++) {
        vifs.push("vifs[]="+ $(this).find('#eth' + i).val());
    }      

    var data = "image_id="+image_id
              +"&instance_spec_id="+instance_spec_id
              +"&host_name="+host_name
              +"&user_data="+user_data
              +"&" + security_groups.join('&')
              +"&" + vifs.join('&')
              +"&ssh_key="+ssh_key_pair
              +"&display_name="+display_name;
    
    request = new DcmgrGUI.Request;
    request.post({
      "url": '/instances',
      "data": data,
      success: function(json,status){
       bt_refresh.element.trigger('dcmgrGUI.refresh');
      }
    });
    $(this).dialog("close");
  }
  
  var bt_launch_instance = new DcmgrGUI.Dialog({
    target:'.launch_instance',
    width:583,
    height:600,
    title:$.i18n.prop('launch_instance_header'),
    path:'/launch_instance',
    callback: function(){
      var self = this;
      
      var loading_image = DcmgrGUI.Util.getLoadingImage('boxes');
      $(this).find('#select_ssh_key_pair').empty().html(loading_image);
      $(this).find("#left_select_list").mask($.i18n.prop('loading_parts'));
      
      var request = new DcmgrGUI.Request;
      var is_ready = {
        'instance_spec': false,
        'ssh_keypair': false,
        'security_groups': false,
        'networks': false,
        'display_name': false
      };

      var ready = function(data) {
        if(data['instance_spec'] == true &&
           data['ssh_keypair'] == true &&
           data['security_groups'] == true &&
           data['networks'] == true &&
           data['display_name'] == true) {  
          bt_launch_instance.disabledButton(1, false);
        } else {
          bt_launch_instance.disabledButton(1, true);
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
        //get instance_specs
        instance_specs:
          request.get({
            "url": '/instance_specs/all.json',
            success: function(json,status){
              var select_html = '<select id="instance_specs" name="instance_specs"></select>';
              $(self).find('#select_instance_specs').empty().html(select_html);

              var results = json.instance_spec.results;
              var size = results.length;
              var select_instance_specs = $(self).find('#instance_specs');
              if(size > 0) { 
                is_ready['instance_spec'] = true;
              }

              for (var i=0; i < size ; i++) {
                var uuid = results[i].result.uuid;
                var html = '<option value="'+ uuid +'">'+uuid+'</option>';
                select_instance_specs.append(html);
              }
            }
          }),
        //get ssh key pairs
        ssh_keypairs:
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
                var html = '<option id="'+ ssh_keypair_id +'" value="'+ ssh_keypair_id +'">'+ssh_keypair_id+'</option>'
                select_keypair.append(html);
              }
            }
        }),
        //get security groups
        security_groups:
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
                  "name" : results[i].result.uuid,
                });
              }

              var security_group = new DcmgrGUI.ItemSelector({
                'left_select_id' : '#left_select_list',
                'right_select_id' : "#right_select_list",
                "data" : data,
                'target' : self
              });
              
              var on_ready = function(size){
                if(size > 0) {
                  is_ready['security_groups'] = true;
                  ready(is_ready);
                } else {
                  is_ready['security_groups'] = false;
                  ready(is_ready);
                }
              }

              $(self).find('#right_button').click(function(){
                security_group.leftToRight();
                on_ready(security_group.getRightSelectionCount());
              });

              $(self).find('#left_button').click(function(){
                security_group.rightToLeft();
                on_ready(security_group.getRightSelectionCount());
              });
            },
            complete: function(json,status){
              $(self).find("#left_select_list").unmask();
            }
        }),

        //get networks
        networks: 
          request.get({
            "url": '/networks/all.json',
            "data": "",
            success: function(json,status){
              var create_select_item = function(name) {
                var select_html = '<select id="' + name + '" name="' + name + '"></select>';
                $(self).find('#select_' + name).empty().html(select_html);
                return $(self).find('#' + name);
              }

              var append_select_item = function(select_item, uuid, name) {
                select_item.append('<option value="'+ uuid +'">'+name+'</option>');
              }

              var create_select_eth = function(name, results) {
                var select_eth = create_select_item(name);
                append_select_item(select_eth, 'none', 'none')
                append_select_item(select_eth, 'disconnected', 'disconnected')

                for (var i=0; i < size ; i++) {
                  append_select_item(select_eth, results[i].result.uuid, results[i].result.uuid + ' - ' + results[i].result.display_name)
                }
              }

              var results = json.network.results;
              var size = results.length;

              is_ready['networks'] = true;
              ready(is_ready);

              for (var i=0; i < 5 ; i++) {
                create_select_eth('eth' + i, results);
              }                
            }
          })

      });
    },
    button: launch_instance_buttons
  });
  
  var delete_backup_image_buttons = {};
  delete_backup_image_buttons[close_button_name] = function() { $(this).dialog("close"); }
  delete_backup_image_buttons[delete_button_name] = function() {
      var image_id = $(this).find('#image_id').val();
      var request = new DcmgrGUI.Request;
      request.del({
	"url": '/machine_images/'+ image_id +'.json',
	success: function(json,status){
	  bt_refresh.element.trigger('dcmgrGUI.refresh');
	}
      });
      $(this).dialog("close");
  }

  var bt_delete_backup_image = new DcmgrGUI.Dialog({
    target:'.delete_backup_image',
    width:400,
    height:250,
    title:$.i18n.prop('delete_backup_image_header'),
    path:'/delete_backup_image',
    button: delete_backup_image_buttons
  });

  bt_launch_instance.target.bind('click',function(){
    if(!bt_launch_instance.is_disabled()) {
      var id = c_list.currentChecked();
      if( id ){
        bt_launch_instance.open({"ids":[id]});
	bt_launch_instance.disabledButton(1, true);
      }
    }
    return false;
  });

  bt_delete_backup_image.target.bind('click',function(){
    if(!bt_delete_backup_image.is_disabled()) {
      var id = c_list.currentChecked();
      if( id ){
	  bt_delete_backup_image.open({"ids":[id]});
      }
    }
    return false;
  });

  var actions = {};
  actions.changeButtonState = function() {
      var id = c_list.currentChecked();
      var row_id = "#row-"+id;
      var state = $(row_id).find('.state').text();
      var owner = $('#mainarea_wide').find('#owner').val();
      var image_owner = $(row_id).find('.owner').text();
      if(state == 'available') {
	  bt_launch_instance.enableDialogButton();
	  if(owner != image_owner){
	      bt_delete_backup_image.disableDialogButton();
	  } else {
	      bt_delete_backup_image.enableDialogButton();
	  }
      } else {
	  bt_launch_instance.disableDialogButton();
	  bt_delete_backup_image.disableDialogButton();
      }
  }

  $(bt_launch_instance.target).button({ disabled: true });
  $(bt_delete_backup_image.target).button({ disabled: true});
  $(bt_refresh.target).button({ disabled: false });

  dcmgrGUI.notification.subscribe('checked_radio', actions, 'changeButtonState');
  dcmgrGUI.notification.subscribe('change_pagenate', bt_launch_instance, 'disableDialogButton');
  dcmgrGUI.notification.subscribe('change_pagenate', bt_delete_backup_image, 'disableDialogButton');
  //list
  c_list.setData(null);
  c_list.update(list_request,true);
}
