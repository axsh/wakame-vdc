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
      "snapshot_id":'',
      "created_at":'',
      "state":''
    }]
  }
  
  DcmgrGUI.Detail.prototype.getEmptyData = function(){
    return {
      "uuid" : "-",
      "size" : "-",
      "snapshot_id" : "-",
      "created_at" : "-",
      "updated_at" : "-",
      "state" : "",
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
  
  var detail_filter = new DcmgrGUI.Filter();
  detail_filter.add(function(data){
    data.item.size = DcmgrGUI.Converter.fromMBtoGB(data.item.size);
    return data;
  });
  
  var attach_button_name = $.i18n.prop('attach_button');
  var detach_button_name = $.i18n.prop('detach_button');
  var close_button_name = $.i18n.prop('close_button');
  var create_button_name = $.i18n.prop('create_button');
  var delete_button_name = $.i18n.prop('delete_button');
  
  c_list.setDetailTemplate({
    template_id:'#volumesDetailTemplate',
    detail_path:'/volumes/show/',
    filter: detail_filter
  });
  
  c_list.element.bind('dcmgrGUI.contentChange',function(event,params){
    var volume = params.data.volume;
    c_pagenate.changeTotal(volume.owner_total);
    c_list.setData(volume.results);
    c_list.multiCheckList(c_list.detail_template);
  });
  
  c_list.filter.add(function(data){
    var results = data.volume.results;
    var size = results.length;
    for(var i = 0; i < size; i++) {
      results[i].result.size = DcmgrGUI.Converter.fromMBtoGB(results[i].result.size);
    }
    return data;
  });
  
  var bt_refresh  = new DcmgrGUI.Refresh();
  
  var create_volume_button = {};
  create_volume_button[create_button_name] = function() {
    var volume_size = $(this).find('#volume_size').val();
    var unit = $(this).find('#unit').find('option:selected').val();
    var storage_pool_id = $(this).find('#storage_pool').find('option:selected').val();
    if(!volume_size){
     $('#volume_size').focus();
     return false;
    }
    var data = "size="+volume_size+"&unit="+unit+"&storage_pool_id="+storage_pool_id;

    $.ajax({
      "type": "POST",
      "async": true,
      "url": '/volumes',
      "dataType": "json",
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
      $(this).find('#select_storage_pool').empty().html(loading_image);
      $.ajax({
        "type": "GET",
        "async": true,
        "url": '/storage_pools/show_storage_pools.json',
        "dataType": "json",
        success: function(json,status){
          var select_html = '<select id="storage_pool" name="storage_pool"></select>';
          $(self).find('#select_storage_pool').empty().html(select_html);
          var results = json.storage_pool.results;
          var size = results.length;
          var select_storage_pool = $(self).find('#storage_pool');
          for (var i=0; i < size ; i++) {
            var uuid = results[i].result.uuid;
            var html = '<option value="'+ uuid +'">'+uuid+'</option>';
            select_storage_pool.append(html);
          }
          
          $(self).find('#volume_size').keyup(function(){
            if( $(this).val() ) {
              bt_create_volume.disabledButton(0, false);
            } else {
              bt_create_volume.disabledButton(0 ,true);
            }
          });
          
          if( $(self).find('#volume_size').val() ) {
            bt_create_volume.disabledButton(0 ,false);
          }
        }
      });
    },
    button:　create_volume_button
  });
  
  bt_create_volume.element.bind('dialogopen',function(){
    bt_create_volume.disabledButton(0, true);
  });

  var delete_volume_buttons = {};
  delete_volume_buttons[close_button_name] = function() { $(this).dialog("close"); };
  delete_volume_buttons[delete_button_name] = function() { 
    var delete_volumes = $(this).find('#delete_volumes').find('li');
    var ids = []
    $.each(delete_volumes,function(){
     ids.push($(this).text())
    })

    var data = $.param({ids:ids})
    $.ajax({
      "type": "DELETE",
      "async": true,
      "url": '/volumes',
      "dataType": "json",
      "data": data,
      success: function(json,status){
        bt_refresh.element.trigger('dcmgrGUI.refresh');
      }
    });
    $(this).dialog("close");
  }
  
  var bt_delete_volume = new DcmgrGUI.Dialog({
    target:'.delete_volume',
    width:400,
    height:200,
    title:$.i18n.prop('delete_volume_header'),
    path:'/delete_volume',
    button: delete_volume_buttons
  });
  
  var create_snapshot_buttons = {};
  create_snapshot_buttons[create_button_name] = function() {
    var volume_snapshots = $(this).find('#create_snapshots').find('li');
    var ids = []
    $.each(volume_snapshots,function(){
     ids.push($(this).text())
    })

    var data = $.param({ids:ids})
    $.ajax({
      "type": "POST",
      "async": true,
      "url": '/snapshots',
      "dataType": "json",
      "data": data,
      success: function(json,status){
        bt_refresh.element.trigger('dcmgrGUI.refresh');
      }
    });
    $(this).dialog("close");
  }
  
  var bt_create_snapshot = new DcmgrGUI.Dialog({
    target:'.create_snapshot',
    width:400,
    height:200,
    title:$.i18n.prop('create_snapshot_header'),
    path:'/create_snapshot',
    button: create_snapshot_buttons
  });
  
  attach_volume_buttons = {};
  attach_volume_buttons[close_button_name] = function() { $(this).dialog("close"); };
  attach_volume_buttons[attach_button_name] = function() {
    var volume_id = $(this).find('#volume_id').val();
    var instance_id = $(this).find('#instance_id').val();
    var data = "volume_id=" + volume_id
    + "&instance_id=" + instance_id;

    $.ajax({
      "type": "PUT",
      "async": true,
      "url": '/volumes/attach',
      "dataType": "json",
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
    button: attach_volume_buttons
  });
  
  detach_volume_buttons = {}
  detach_volume_buttons[close_button_name] = function() { $(this).dialog("close"); };
  detach_volume_buttons[detach_button_name] = function() { 
    var detach_volumes = $(this).find('#detach_volumes').find('li');
    var ids = []
    $.each(detach_volumes,function(){
     ids.push($(this).text())
    })

    var data = $.param({ids:ids})
    $.ajax({
      "type": "PUT",
      "async": true,
      "url": '/volumes/detach',
      "dataType": "json",
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
  });
  
  bt_delete_volume.target.bind('click',function(){
    bt_delete_volume.open(c_list.getCheckedInstanceIds());
  });

  bt_create_snapshot.target.bind('click',function(){
    bt_create_snapshot.open(c_list.getCheckedInstanceIds());
  });

  bt_attach_volume.target.bind('click',function(){
    bt_attach_volume.open(c_list.getCheckedInstanceIds());
  });

  bt_detach_volume.target.bind('click',function(){
    bt_detach_volume.open(c_list.getCheckedInstanceIds());
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
  
  dcmgrGUI.notification.subscribe('checked_box', bt_delete_volume, 'enableDialogButton');
  dcmgrGUI.notification.subscribe('checked_box', bt_create_snapshot, 'enableDialogButton');
  dcmgrGUI.notification.subscribe('unchecked_box', bt_delete_volume, 'disableDialogButton');
  dcmgrGUI.notification.subscribe('unchecked_box', bt_create_snapshot, 'disableDialogButton');
  dcmgrGUI.notification.subscribe('change_pagenate', bt_delete_volume, 'disableDialogButton');
  dcmgrGUI.notification.subscribe('change_pagenate', bt_create_snapshot, 'disableDialogButton');
  
  $(bt_create_volume.target).button({ disabled: false });
  $(bt_delete_volume.target).button({ disabled: true });
  $(bt_create_snapshot.target).button({ disabled: true });
  $(bt_refresh.target).button({ disabled: false });
  
  //list
  c_list.setData(null);
  c_list.update(list_request,true);  
}