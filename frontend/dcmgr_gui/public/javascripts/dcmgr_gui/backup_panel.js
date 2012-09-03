DcmgrGUI.prototype.backupPanel = function(){
  var total = 0;
  var maxrow = 10;
  var page = 1;
  var list_request = { 
    "url" : DcmgrGUI.Util.getPagePath('/backups/list/',page),
    "data" : DcmgrGUI.Util.getPagenateData(page,maxrow)
  };
    
  DcmgrGUI.List.prototype.getEmptyData = function(){
    return [{
      "uuid":'',
      "size":'',
      "origin_volume_id":'',
      "created_at":'',
      "state":'',
      "progress":''
    }]
  }
  
  DcmgrGUI.Detail.prototype.getEmptyData = function(){
    return {
      "uuid" : "-",
      "size" : "-",
      "origin_volume_id" : "-",
      "created_at" : "-",
      "updated_at" : "-",
      "state" : "",
      "progress" : ""
    }
  }
  
  var create_button_name = $.i18n.prop('create_button');
  var delete_button_name = $.i18n.prop('delete_button');
  var close_button_name = $.i18n.prop('close_button');
  var update_button_name = $.i18n.prop('update_button');
  
  var c_pagenate = new DcmgrGUI.Pagenate({
    row:maxrow,
    total:total
  });
  
  var c_list = new DcmgrGUI.List({
    element_id:'#display_backups',
    template_id:'#backupsListTemplate',
    maxrow:maxrow,
    page:page
  });
  
  c_list.setDetailTemplate({
    template_id:'#backupsDetailTemplate',
    detail_path:'/backups/show/'
  });
  
  c_list.element.bind('dcmgrGUI.contentChange',function(event,params){
    var backup = params.data.backup_object;
    c_pagenate.changeTotal(backup.total);
    c_list.setData(backup.results);
    c_list.multiCheckList(c_list.detail_template);
    c_list.element.find(".edit_backup").each(function(key,value){
      $(this).button({ disabled: false });
      var uuid = $(value).attr('id').replace(/edit_(bo-[a-z0-9]+)/,'$1');
      if( uuid ){
        $(this).bind('click',function(){
          bt_edit_backup.open({"ids":[uuid]});
        });
      } else {
        $(this).button({ disabled: true });
      }
    });

    var edit_backup_buttons = {};
    edit_backup_buttons[close_button_name] = function() { $(this).dialog("close"); };
    edit_backup_buttons[update_button_name] = function(event) {
      var backup_id = $(this).find('#backup_object_id').val();
      var display_name = $(this).find('#backup_display_name').val();
      var data = 'display_name=' + display_name;

      var request = new DcmgrGUI.Request;
      request.put({
        "url": '/backups/'+ backup_id +'.json',
        "data": data,
        success: function(json, status){
          bt_refresh.element.trigger('dcmgrGUI.refresh');
        }
      });
      $(this).dialog("close");
    }

    bt_edit_backup = new DcmgrGUI.Dialog({
      target:'.edit_backup',
      width:500,
      height:200,
      title:$.i18n.prop('edit_backup_header'),
      path:'/edit_backup',
      button: edit_backup_buttons,
      callback: function(){
        var params = { 'button': bt_edit_backup, 'element_id': 1 };
        $(this).find('#backup_display_name').bind('paste', params, DcmgrGUI.Util.availableTextField);
        $(this).find('#backup_display_name').bind('keyup', params, DcmgrGUI.Util.availableTextField);
      }
    });
  });

  c_list.filter.add(function(data){
    var results = data.backup_object.results;
    var size = results.length;
    for(var i = 0; i < size; i++) {
      results[i].result.size = DcmgrGUI.Converter.fromBtoKB(results[i].result.size);
    }
    return data;
  });
  
  c_list.filter.add(function(data){
    var results = data.backup_object.results;
    var size = results.length;
    for(var i = 0; i < size; i++) {
      results[i].result.created_at = DcmgrGUI.date.parseISO8601(results[i].result.created_at);
      results[i].result.created_at = DcmgrGUI.date.setTimezone(results[i].result.created_at, dcmgrGUI.getConfig('time_zone'));
      results[i].result.created_at = DcmgrGUI.date.getI18n(results[i].result.created_at);
    }
    return data;
  });

  c_list.detail_filter.add(function(data){
    data.item.size = DcmgrGUI.Converter.fromBtoKB(data.item.size);
    return data;
  });
 
  var bt_refresh  = new DcmgrGUI.Refresh();
  
  var create_volume_buttons = {};
  create_volume_buttons[close_button_name] = function() { $(this).dialog("close"); };
  create_volume_buttons[create_button_name] = function() { 
    var display_name = $(this).find('#backup_display_name').val();
    var create_volumes = $(this).find('#backups').find('td.backup_id');
    var ids = []
    $.each(create_volumes,function(){
     ids.push($(this).text())
    })

    var data = $.param({ids:ids, display_name:display_name})
    
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
    height:250,
    title:$.i18n.prop('create_volume_header'),
    path:'/create_volume_from_backup',
    callback: function(){
      var params = { 'button': bt_create_volume, 'element_id': 1 };
      $(this).find("#backup_display_name").bind('paste', params, DcmgrGUI.Util.availableTextField)
      $(this).find("#backup_display_name").bind('keyup', params, DcmgrGUI.Util.availableTextField)
    },
    button: create_volume_buttons
  });
  
  var delete_backup_buttons = {};
  delete_backup_buttons[close_button_name] = function() { $(this).dialog("close"); }
  delete_backup_buttons[delete_button_name] = function() { 
    var delete_backups = $(this).find('#backups').find('td.backup_id');
    var ids = []
    $.each(delete_backups,function(){
     ids.push($(this).text())
    })

    var data = $.param({ids:ids});
    
    var request = new DcmgrGUI.Request;
    request.del({
      "url": '/backups/delete',
      "data": data,
      success: function(json,status){
        bt_delete_backup.disableDialogButton();
        bt_refresh.element.trigger('dcmgrGUI.refresh');
      }
    });
    c_list.changeStatus('deleting');
    $(this).dialog("close");
  }
  
  var bt_delete_backup = new DcmgrGUI.Dialog({
    target:'.delete_backup',
    width:400,
    height:200,
    title:$.i18n.prop('delete_backup_header'),
    path:'/delete_backup',
    button: delete_backup_buttons
  });
  
  bt_create_volume.target.bind('click',function(){
    if(!bt_create_volume.is_disabled()) {
      bt_create_volume.open(c_list.getCheckedInstanceIds());
      bt_create_volume.disabledButton(1, true);
    }
  });
  
  bt_delete_backup.target.bind('click',function(){
    if(!bt_delete_backup.is_disabled()) {
      bt_delete_backup.open(c_list.getCheckedInstanceIds());
    }
  });

  bt_refresh.element.bind('dcmgrGUI.refresh',function(){
    c_list.page = c_pagenate.current_page;
    list_request.url = DcmgrGUI.Util.getPagePath('/backups/list/',c_list.page);
    list_request.data = DcmgrGUI.Util.getPagenateData(c_pagenate.start,c_pagenate.row);
    c_list.element.trigger('dcmgrGUI.updateList',{request:list_request})
    //update detail
    $.each(c_list.checked_list,function(check_id,obj){
      $($('#detail').find('#'+check_id)).remove();
      c_list.checked_list[check_id].c_detail.update({
        url:DcmgrGUI.Util.getPagePath('/backups/show/',check_id)
      },true);
    });
  });
  
  c_pagenate.element.bind('dcmgrGUI.updatePagenate',function(){
    c_list.clearCheckedList();
    $('#detail').html('');
    bt_refresh.element.trigger('dcmgrGUI.refresh');
  });

  var actions = {};
  actions.changeButtonState = function() {
    var ids = c_list.currentMultiChecked()['ids'];
    var is_available = false;
    var is_deleting = false;
    var flag = true;

    $.each(ids, function(key, uuid){
      var row_id = '#row-'+uuid;
      var state = $(row_id).find('.state').text();
      if(state == 'available') {
        is_available = true;
      } else if(state == 'deleting') {
        is_deleting = true;
      } else{
        flag = false;
      }
    });

    if(is_available == true && flag == true){
      bt_create_volume.enableDialogButton();
      bt_delete_backup.enableDialogButton();
    }else{
      bt_create_volume.disableDialogButton();
      bt_delete_backup.disableDialogButton();
    }

    if(is_deleting == true) {
      bt_delete_backup.enableDialogButton();
    }
  }

  dcmgrGUI.notification.subscribe('checked_box', actions, 'changeButtonState');
  dcmgrGUI.notification.subscribe('unchecked_box', actions, 'changeButtonState');
  dcmgrGUI.notification.subscribe('change_pagenate', bt_delete_backup, 'disableDialogButton');

  $(bt_create_volume.target).button({ disabled: true });
  $(bt_delete_backup.target).button({ disabled: true });
  $(bt_refresh.target).button({ disabled: false });
  
  //list
  c_list.setData(null);
  c_list.update(list_request,true);
  
}
