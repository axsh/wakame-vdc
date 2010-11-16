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
      "state" : "",
    }
  }
  
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
  
  c_list.setDetailTemplate({
    template_id:'#snapshotsDetailTemplate',
    detail_path:'/snapshots/show/'
  });
  
  c_list.element.bind('dcmgrGUI.contentChange',function(event,params){
    var snapshot = params.data.volume_snapshot;
    c_pagenate.changeTotal(snapshot.owner_total);
    c_list.setData(snapshot.results);
    c_list.multiCheckList(c_list.detail_template);
  });
  
  var bt_refresh  = new DcmgrGUI.Refresh();
  
  var bt_create_volume = new DcmgrGUI.Dialog({
    target:'.create_volume',
    width:400,
    height:200,
    title:'Create Volume',
    path:'/create_volume_from_snapshot',
    button:{
     "Create": function() { 
       var create_volumes = $(this).find('#create_volumes').find('li');
       var ids = []
       $.each(create_volumes,function(){
         ids.push($(this).text())
       })
       
       var data = $.param({ids:ids})
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
    }
  });

  var bt_delete_snapshot = new DcmgrGUI.Dialog({
    target:'.delete_snapshot',
    width:400,
    height:200,
    title:'Delete snapshot',
    path:'/delete_snapshot',
    button:{
     "Close": function() { $(this).dialog("close"); },
     "Yes, Delete": function() { 
       var delete_snapshots = $(this).find('#delete_snapshots').find('li');
       var ids = []
       $.each(delete_snapshots,function(){
         ids.push($(this).text())
       })
       
       var data = $.param({ids:ids})
       $.ajax({
          "type": "DELETE",
          "async": true,
          "url": '/snapshots/delete',
          "dataType": "json",
          "data": data,
          success: function(json,status){
            bt_refresh.element.trigger('dcmgrGUI.refresh');
          }
        });
       c_list.changeStatus('deleting');
       $(this).dialog("close");
      }
    }
  });
  
  bt_create_volume.target.bind('click',function(){
    bt_create_volume.open(c_list.getCheckedInstanceIds());
  });
  
  bt_delete_snapshot.target.bind('click',function(){
    bt_delete_snapshot.open(c_list.getCheckedInstanceIds());
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

  //list
  c_list.setData(null);
  c_list.update(list_request,true);
  
}