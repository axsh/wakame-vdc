DcmgrGUI.prototype.volumePanel = function(){
  var total = 0;
  var maxrow = 10;
  var page = 1;
  var list_request = { 
    "url" : DcmgrGUI.Util.getPagePath('/volumes/list/',page),
    "data" : DcmgrGUI.Util.getPagenateData(page,maxrow)
  };
    
  DcmgrGUI.List.prototype.getEmptyData = function(){
    return [{
      "uuid":'',
      "size":'',
      "backup_object_id":'',
      "created_at":'',
      "state":''
    }]
  }
  
  DcmgrGUI.Detail.prototype.getEmptyData = function(){
    return {
      "uuid" : "-",
      "size" : "-",
      "backup_object_id" : "-",
      "created_at" : "-",
      "updated_at" : "-",
      "state" : ""
    }
  }

  var c_pagenate = new DcmgrGUI.Pagenate({
    row:maxrow,
    total:total
  });
  
  var c_list = new DcmgrGUI.List({
    element_id:'#display_volumes',
    template_id:'#volumesListTemplate',
    maxrow:maxrow,
    page:page
  });
  
  var attach_button_name = $.i18n.prop('attach_button');
  var detach_button_name = $.i18n.prop('detach_button');
  var close_button_name = $.i18n.prop('close_button');
  var create_button_name = $.i18n.prop('create_button');
  var delete_button_name = $.i18n.prop('delete_button');
  var update_button_name = $.i18n.prop('update_button');
  
  c_list.setDetailTemplate({
    template_id:'#volumesDetailTemplate',
    detail_path:'/volumes/show/'
  });
  
  c_list.element.bind('dcmgrGUI.contentChange',function(event,params){
    var volume = params.data.volume;
    c_pagenate.changeTotal(volume.total);
    c_list.setData(volume.results);
    c_list.multiCheckList(c_list.detail_template);
    c_list.element.find(".edit_volume").each(function(key,value){
      $(this).button({ disabled: false });
      var uuid = $(value).attr('id').replace(/edit_(vol-[a-z0-9]+)/,'$1');
      if( uuid ){
        $(this).bind('click',function(){
          bt_edit_volume.open({"ids":[uuid]});
        });
      } else {
        $(this).button({ disabled: true });
      }
    });

    var edit_volume_buttons = {};
    edit_volume_buttons[close_button_name] = function() { $(this).dialog("close"); };
    edit_volume_buttons[update_button_name] = function(event) {
      var volume_id = $(this).find('#volume_id').val();
      var display_name = $(this).find('#volume_display_name').val();
      var data = 'display_name=' + display_name;

      var request = new DcmgrGUI.Request;
      request.put({
        "url": '/volumes/'+ volume_id +'.json',
        "data": data,
        success: function(json, status){
          bt_refresh.element.trigger('dcmgrGUI.refresh');
        }
      });
      $(this).dialog("close");
    }

    bt_edit_volume = new DcmgrGUI.Dialog({
      target:'.edit_volume',
      width:500,
      height:200,
      title:$.i18n.prop('edit_volume_header'),
      path:'/edit_volume',
      button: edit_volume_buttons,
      callback: function(){
        var params = { 'button': bt_edit_volume, 'element_id': 1 };
        $(this).find('#volume_display_name').bind('paste', params, DcmgrGUI.Util.availableTextField);
        $(this).find('#volume_display_name').bind('cut', params, DcmgrGUI.Util.availableTextField);
        $(this).find('#volume_display_name').bind('keyup', params, DcmgrGUI.Util.availableTextField);
      }
    });
  });
  
  c_list.filter.add(function(data){
    var results = data.volume.results;
    var size = results.length;
    for(var i = 0; i < size; i++) {
      results[i].result.created_at = DcmgrGUI.date.parseISO8601(results[i].result.created_at);
      results[i].result.created_at = DcmgrGUI.date.setTimezone(results[i].result.created_at, dcmgrGUI.getConfig('time_zone'));
      results[i].result.created_at = DcmgrGUI.date.getI18n(results[i].result.created_at);
    }
    return data;
  });

  var bt_refresh  = new DcmgrGUI.Refresh();
  
  var create_volume_buttons = {};
  create_volume_buttons[close_button_name] = function() { $(this).dialog("close"); };
  create_volume_buttons[create_button_name] = function() {
    var display_name = $(this).find('#display_name').val();
    var volume_size = $(this).find('#volume_size').val();
    var unit = $(this).find('#unit').find('option:selected').val();
    if(!volume_size){
     $('#volume_size').focus();
     return false;
    }
    var data = "size="+volume_size+"&unit="+unit+"&display_name="+display_name;
    
    var request = new DcmgrGUI.Request;
    request.post({
      "url": '/volumes',
      "data": data,
      success: function(json,status){
        bt_refresh.element.trigger('dcmgrGUI.refresh');
      }
    });
    $(this).dialog("close");
  }

  var bt_create_volume = new DcmgrGUI.Dialog({
    target:'.create_volume',
    width:400,
    height:200,
    title:$.i18n.prop('create_volume_header'),
    path:'/create_volume',
    callback: function(){
      var self = this;
      var loading_image = DcmgrGUI.Util.getLoadingImage('boxes');
      $(this).find('#select_storage_node').empty().html(loading_image);
      
      var request = new DcmgrGUI.Request;
      var is_ready = {
        'display_name': false,
        'volume_size': false
      }

      var ready = function(data) {
        if(data['display_name'] == true &&
           data['volume_size'] == true) {
          bt_create_volume.disabledButton(1, false);
        } else {
          bt_create_volume.disabledButton(1, true);
        }
      }

      var display_name_params = {'name': 'display_name', 'is_ready': is_ready, 'ready': ready};
      $(this).find('#display_name').bind('keyup', display_name_params, DcmgrGUI.Util.checkTextField);
      $(this).find('#display_name').bind('paste', display_name_params, DcmgrGUI.Util.checkTextField);
      $(this).find('#display_name').bind('cut', display_name_params, DcmgrGUI.Util.checkTextField);

      var volume_size_params = {'name': 'volume_size', 'is_ready': is_ready, 'ready': ready};
      $(this).find('#volume_size').bind('keyup', volume_size_params, DcmgrGUI.Util.checkTextField);
      $(this).find('#volume_size').bind('paste', volume_size_params, DcmgrGUI.Util.checkTextField);
      $(this).find('#volume_size').bind('cut', volume_size_params, DcmgrGUI.Util.checkTextField);

      request.get({
        "url": '/storage_nodes/show_storage_nodes.json',
        success: function(json,status){
          var select_html = '<select id="storage_node" name="storage_node"></select>';
          $(self).find('#select_storage_node').empty().html(select_html);
          var results = json.storage_node.results;
          var size = results.length;
          var select_storage_node = $(self).find('#storage_node');
          for (var i=0; i < size ; i++) {
            var uuid = results[i].result.uuid;
            var html = '<option value="'+ uuid +'">'+uuid+'</option>';
            select_storage_node.append(html);
          }

          var params = { 'button': bt_create_volume, 'element_id': 1 };
        }
      });
    },
    button:　create_volume_buttons
  });
  
  var delete_volume_buttons = {};
  delete_volume_buttons[close_button_name] = function() { $(this).dialog("close"); };
  delete_volume_buttons[delete_button_name] = function() { 
    var delete_volumes = $(this).find('#volumes').find('td.volume_id');
    var ids = []
    $.each(delete_volumes,function(){
     ids.push($(this).text())
    })

    var data = $.param({ids:ids});
    
    var request = new DcmgrGUI.Request;
    request.del({
      "url": '/volumes',
      "data": data,
      success: function(json,status){
        bt_delete_volume.disableDialogButton();
        bt_refresh.element.trigger('dcmgrGUI.refresh');
      }
    });
    
    $(this).dialog("close");
  }
  
  var bt_delete_volume = new DcmgrGUI.Dialog({
    target:'.delete_volume',
    width:400,
    height:250,
    title:$.i18n.prop('delete_volume_header'),
    path:'/delete_volume',
    button: delete_volume_buttons
  });
  
  var create_backup_buttons = {};
  create_backup_buttons[close_button_name] = function() { $(this).dialog("close"); }; 
  create_backup_buttons[create_button_name] = function() {
    var display_name = $(this).find('#backup_display_name').val();
    var volume_backups = $(this).find('#backups').find('td.volume_id');
    var destination = $(this).find('#destination').val();
    var ids = []
    $.each(volume_backups,function(){
     ids.push($(this).text())
    })

    var data = $.param({ids:ids, destination:destination, display_name:display_name});
    var request = new DcmgrGUI.Request;
    request.put({
      "url": '/volumes/backup',
      "data": data,
      success: function(json,status){
        bt_refresh.element.trigger('dcmgrGUI.refresh');
      }
    });
    
    $(this).dialog("close");
  }
  
  var bt_create_backup = new DcmgrGUI.Dialog({
    target:'.create_backup',
    width:400,
    height:250,
    title:$.i18n.prop('create_backup_header'),
    path:'/create_backup',
    button: create_backup_buttons,
    callback: function() {
      var self = this;
      var params = { 'button': bt_create_backup, 'element_id': 1 };
      $(self).find("#backup_display_name").bind('paste', params, DcmgrGUI.Util.availableTextField)
      $(self).find("#backup_display_name").bind('cut', params, DcmgrGUI.Util.availableTextField)
      $(self).find("#backup_display_name").bind('keyup', params, DcmgrGUI.Util.availableTextField)
    }
  });
  
  attach_volume_buttons = {};
  attach_volume_buttons[close_button_name] = function() { $(this).dialog("close"); };
  attach_volume_buttons[attach_button_name] = function() {
    var attach_volumes = $(this).find('#volumes').find('td.volume_id');
    var volume_ids = []
    $.each(attach_volumes,function(){
     volume_ids.push($(this).text())
    })  

    var instance_id = $(this).find('#instance_id').val();
    var data = $.param({'instance_id': instance_id, volume_ids: volume_ids})
    var request = new DcmgrGUI.Request;

    request.put({
      "url": '/volumes/attach',
      "data": data,
      success: function(json,status){
        bt_refresh.element.trigger('dcmgrGUI.refresh');
      }
    });
    
    $(this).dialog("close");
  }
  
  var bt_attach_volume = new DcmgrGUI.Dialog({
    target:'.attach_volume',
    width:400,
    height:200,
    title:$.i18n.prop('attach_volume_header'),
    path:'/attach_volume',
    callback: function() {
      var params = { 'button': bt_attach_volume, 'element_id': 1 };
      $(this).find('#instance_id').bind('paste', params, DcmgrGUI.Util.availableTextField);
      $(this).find('#instance_id').bind('keyup', params, DcmgrGUI.Util.availableTextField);
    },
    button: attach_volume_buttons
  });
  
  detach_volume_buttons = {}
  detach_volume_buttons[close_button_name] = function() { $(this).dialog("close"); };
  detach_volume_buttons[detach_button_name] = function() { 
    var detach_volumes = $(this).find('#volumes').find('td.volume_id');
    var ids = []
    $.each(detach_volumes,function(){
     ids.push($(this).text())
    })

    var data = $.param({ids:ids});
    
    var request = new DcmgrGUI.Request;
    request.put({
      "url": '/volumes/detach',
      "data": data,
      success: function(json,status){
        bt_refresh.element.trigger('dcmgrGUI.refresh');
      }
    });
    
    $(this).dialog("close");
  }
  
  var bt_detach_volume = new DcmgrGUI.Dialog({
    target:'.detach_volume',
    width:400,
    height:200,
    title:$.i18n.prop('detach_volume_header'),
    path:'/detach_volume',
    button: detach_volume_buttons
  });
  
  bt_create_volume.target.bind('click',function(){
    bt_create_volume.open();
    bt_create_volume.disabledButton(1, true);
  });
  
  bt_delete_volume.target.bind('click',function(){
    if(!bt_delete_volume.is_disabled()) {
      bt_delete_volume.open(c_list.getCheckedInstanceIds());
    }
  });

  bt_create_backup.target.bind('click',function(){
    if(!bt_create_backup.is_disabled()) { 
      bt_create_backup.open(c_list.getCheckedInstanceIds());
      bt_create_backup.disabledButton(1, true);
    }
  });

  bt_refresh.element.bind('dcmgrGUI.refresh',function(){
    c_list.page = c_pagenate.current_page;
    list_request.url = DcmgrGUI.Util.getPagePath('/volumes/list/',c_list.page);
    list_request.data = DcmgrGUI.Util.getPagenateData(c_pagenate.start,c_pagenate.row);
    c_list.element.trigger('dcmgrGUI.updateList',{request:list_request})
    
    //update detail
    $.each(c_list.checked_list,function(check_id,obj){
      $($('#detail').find('#'+check_id)).remove();
      c_list.checked_list[check_id].c_detail.update({
        url:DcmgrGUI.Util.getPagePath('/volumes/show/',check_id)
      },true);
    });
  });
  
  c_pagenate.element.bind('dcmgrGUI.updatePagenate',function(){
    c_list.clearCheckedList();
    $('#detail').html('');
    bt_refresh.element.trigger('dcmgrGUI.refresh');
  });

  var selectmenu = $('#volume_action').selectmenu({
    width: 150,
    menuWidth: 150,
    handleWidth: 26,
    style:'dropdown',
    select: function(event){
      var select_action = $(this).val()
      if (select_action == "attach_volume") {
        var is_attached = false;
        var flag = true;
        $.each(c_list.getCheckedInstanceIds(), function(key, uuid){
          var row_id = '#row-'+uuid;
          var state = $(row_id).find('.state').text();
          if(state == 'available' && state != 'attached') {
            is_attached = true;
          } else {
            flag = false;
          }
        });

        if(is_attached == true && flag == true) {
          bt_attach_volume.open(c_list.getCheckedInstanceIds());
          bt_attach_volume.disabledButton(1, true);
        }
      }else if(select_action == "detach_volume") {
        var is_detached = false;
        var flag = true;
        $.each(c_list.getCheckedInstanceIds(), function(key, uuid){
          var row_id = '#row-'+uuid;
          var state = $(row_id).find('.state').text();
          if(state == 'attached') {
            is_detached = true;
          } else {
            flag = false;
          }
        });
        
        if(is_detached == true && flag == true) {
          bt_detach_volume.open(c_list.getCheckedInstanceIds());
        }
      }
    }
  });
 
  selectmenu.data('selectmenu').disableButton();
  $(bt_create_volume.target).button({ disabled: false });
  $(bt_delete_volume.target).button({ disabled: true });
  $(bt_create_backup.target).button({ disabled: true });
  $(bt_refresh.target).button({ disabled: false });
  
  var actions = {};
  actions.changeButtonState = function() {
    var ids = c_list.currentMultiChecked()['ids'];
    var is_available = false;
    var is_attached = false;
    var is_deleting = false;
    var flag = true;

    $.each(ids, function(key, uuid){
      var row_id = '#row-'+uuid;
      var state = $(row_id).find('.state').text();
      if(state == 'available') {
        is_available = true;
      } else if(state == 'attached') {
        is_attached = true;
      } else if(state == 'deleting') {
        is_deleting = true;
      } else{
        flag = false;
      }
    });

    if (flag == true){

      if(is_available == true && is_attached == true) {
        bt_delete_volume.enableDialogButton();
        bt_create_backup.enableDialogButton();
        selectmenu.data('selectmenu').disableButton();
      }
 
      if(is_available == false && is_attached == true) {
        bt_delete_volume.disableDialogButton();
        bt_create_backup.disableDialogButton();
        selectmenu.data('selectmenu').enableButton();
      }
      
      if(is_available == true && is_attached == false) {
        bt_delete_volume.enableDialogButton();
        bt_create_backup.enableDialogButton();
        selectmenu.data('selectmenu').enableButton();
      }
      
      if (is_available == false && is_attached == false) {
        bt_delete_volume.disableDialogButton();
        bt_create_backup.disableDialogButton();
        selectmenu.data('selectmenu').disableButton();
      }

      if (is_deleting == true) {
        bt_delete_volume.enableDialogButton();
      }

    } else{
      bt_delete_volume.disableDialogButton();
      bt_create_backup.disableDialogButton();
      selectmenu.data('selectmenu').disableButton();
    }
  }
  
  dcmgrGUI.notification.subscribe('checked_box', actions, 'changeButtonState');
  dcmgrGUI.notification.subscribe('unchecked_box', actions, 'changeButtonState');
  dcmgrGUI.notification.subscribe('change_pagenate', bt_delete_volume, 'disableDialogButton');
  dcmgrGUI.notification.subscribe('change_pagenate', bt_create_backup, 'disableDialogButton');
  dcmgrGUI.notification.subscribe('change_pagenate', selectmenu.data('selectmenu'), 'disableButton');
  
  //list
  c_list.setData(null);
  c_list.update(list_request,true);  
}
