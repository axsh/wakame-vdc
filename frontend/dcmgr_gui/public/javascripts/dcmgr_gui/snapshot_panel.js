DcmgrGUI.prototype.snapshotPanel = function(){
  var total = 0;
  var maxrow = 10;
  var page = 1;
  var list_request = { 
    "url" : DcmgrGUI.Util.getPagePath('/snapshots/list/',page),
    "data" : DcmgrGUI.Util.getPagenateData(page,maxrow)
  };
    
  DcmgrGUI.List.prototype.getEmptyData = function(){
    return [{
      "uuid":'',
      "size":'',
      "origin_volume_id":'',
      "created_at":'',
      "state":''
    }]
  }
  
  DcmgrGUI.Detail.prototype.getEmptyData = function(){
    return {
      "uuid" : "-",
      "size" : "-",
      "origin_volume_id" : "-",
      "created_at" : "-",
      "updated_at" : "-",
      "state" : ""
    }
  }
  
  var create_button_name = $.i18n.prop('create_button');
  var delete_button_name = $.i18n.prop('delete_button');
  var close_button_name = $.i18n.prop('close_button');
  
  var c_pagenate = new DcmgrGUI.Pagenate({
    row:maxrow,
    total:total
  });
  
  var c_list = new DcmgrGUI.List({
    element_id:'#display_snapshots',
    template_id:'#snapshotsListTemplate',
    maxrow:maxrow,
    page:page
  });
  
  var detail_filter = new DcmgrGUI.Filter();
  detail_filter.add(function(data){
    data.item.size = DcmgrGUI.Converter.fromMBtoGB(data.item.size);
    return data;
  });
  
  c_list.setDetailTemplate({
    template_id:'#snapshotsDetailTemplate',
    detail_path:'/snapshots/show/',
    filter: detail_filter
  });
  
  c_list.element.bind('dcmgrGUI.contentChange',function(event,params){
    var snapshot = params.data.volume_snapshot;
    c_pagenate.changeTotal(snapshot.owner_total);
    c_list.setData(snapshot.results);
    c_list.multiCheckList(c_list.detail_template);
  });
  
  c_list.filter.add(function(data){
    var results = data.volume_snapshot.results;
    var size = results.length;
    for(var i = 0; i < size; i++) {
      results[i].result.size = DcmgrGUI.Converter.fromMBtoGB(results[i].result.size);
    }
    return data;
  });
  
  var bt_refresh  = new DcmgrGUI.Refresh();
  
  var create_volume_button = {};
  create_volume_button[create_button_name] = function() { 
    var create_volumes = $(this).find('#create_volumes').find('li');
    var ids = []
    $.each(create_volumes,function(){
     ids.push($(this).text())
    })

    var data = $.param({ids:ids})
    
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
    path:'/create_volume_from_snapshot',
    button: create_volume_button
  });
  
  var delete_snapshot_buttons = {};
  delete_snapshot_buttons[close_button_name] = function() { $(this).dialog("close"); }
  delete_snapshot_buttons[delete_button_name] = function() { 
    var delete_snapshots = $(this).find('#delete_snapshots').find('li');
    var ids = []
    $.each(delete_snapshots,function(){
     ids.push($(this).text())
    })

    var data = $.param({ids:ids});
    
    var request = new DcmgrGUI.Request;
    request.del({
      "url": '/snapshots/delete',
      "data": data,
      success: function(json,status){
        bt_delete_snapshot.disableDialogButton();
        bt_refresh.element.trigger('dcmgrGUI.refresh');
      }
    });
    c_list.changeStatus('deleting');
    $(this).dialog("close");
  }
  
  var bt_delete_snapshot = new DcmgrGUI.Dialog({
    target:'.delete_snapshot',
    width:400,
    height:200,
    title:$.i18n.prop('delete_snapshot_header'),
    path:'/delete_snapshot',
    button: delete_snapshot_buttons
  });
  
  bt_create_volume.target.bind('click',function(){
    if(!bt_create_volume.is_disabled()) {
      bt_create_volume.open(c_list.getCheckedInstanceIds());
    }
  });
  
  bt_delete_snapshot.target.bind('click',function(){
    if(!bt_delete_snapshot.is_disabled()) {
      bt_delete_snapshot.open(c_list.getCheckedInstanceIds());
    }
  });

  bt_refresh.element.bind('dcmgrGUI.refresh',function(){
    c_list.page = c_pagenate.current_page;
    list_request.url = DcmgrGUI.Util.getPagePath('/snapshots/list/',c_list.page);
    list_request.data = DcmgrGUI.Util.getPagenateData(c_pagenate.start,c_pagenate.row);
    c_list.element.trigger('dcmgrGUI.updateList',{request:list_request})
    //update detail
    $.each(c_list.checked_list,function(check_id,obj){
      $($('#detail').find('#'+check_id)).remove();
      c_list.checked_list[check_id].c_detail.update({
        url:DcmgrGUI.Util.getPagePath('/snapshots/show/',check_id)
      },true);
    });
  });
  
  c_pagenate.element.bind('dcmgrGUI.updatePagenate',function(){
    c_list.clearCheckedList();
    $('#detail').html('');
    bt_refresh.element.trigger('dcmgrGUI.refresh');
  });

  var state_check = function() {
    var ids = c_list.currentMultiChecked()['ids'];
    var is_available = false;
    var flag = true;

    $.each(ids, function(key, uuid){
      var row_id = '#row-'+uuid;
      var state = $(row_id).find('.state').text();
      if(state == 'available') {
        is_available = true;
      } else{
        flag = false;
      }
    });

    if(is_available == true && flag == true){
      bt_create_volume.enableDialogButton();
      bt_delete_snapshot.enableDialogButton();
    }else{
      bt_create_volume.disableDialogButton();
      bt_delete_snapshot.disableDialogButton();
    }
    return false;
  }

  dcmgrGUI.notification.add_evaluation(dcmgrGUI.notification.subscribe('checked_box', bt_create_volume, 'enableDialogButton'), state_check);
  dcmgrGUI.notification.add_evaluation(dcmgrGUI.notification.subscribe('checked_box', bt_delete_snapshot, 'enableDialogButton'), state_check);
  dcmgrGUI.notification.add_evaluation(dcmgrGUI.notification.subscribe('unchecked_box', bt_create_volume, 'disableDialogButton'), state_check);
  dcmgrGUI.notification.add_evaluation(dcmgrGUI.notification.subscribe('unchecked_box', bt_delete_snapshot, 'disableDialogButton'), state_check);
  dcmgrGUI.notification.subscribe('change_pagenate', bt_delete_snapshot, 'disableDialogButton');

  $(bt_create_volume.target).button({ disabled: true });
  $(bt_delete_snapshot.target).button({ disabled: true });
  $(bt_refresh.target).button({ disabled: false });
  
  //list
  c_list.setData(null);
  c_list.update(list_request,true);
  
}
