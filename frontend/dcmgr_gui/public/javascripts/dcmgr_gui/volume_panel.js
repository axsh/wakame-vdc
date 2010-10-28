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
  
  c_list.setDetailTemplate({
    template_id:'#volumesDetailTemplate',
    detail_path:'/volumes/show/'
  });
  
  c_list.element.bind('dcmgrGUI.contentChange',function(event,params){
    var volume = params.data.volume;
    c_pagenate.changeTotal(volume.owner_total);
    c_list.setData(volume.results);
    c_list.multiCheckList(c_list.detail_template);
  });
  
  var bt_refresh  = new DcmgrGUI.Refresh();
  
  var bt_create_volume = new DcmgrGUI.Dialog({
    target:'.create_volume',
    width:400,
    height:200,
    title:'Create Volume',
    path:'/create_volume',
    button:{
     "Create": function() { 
       var volume_size = $(this).find('#volume_size').val();
       var unit = $(this).find('#unit').find('option:selected').val();
       if(!volume_size){
         $('#volume_size').focus();
         return false;
       }
       var data = "size="+volume_size+"&unit="+unit;
       
       $.ajax({
          "type": "POST",
          "async": true,
          "url": '/volumes/create',
          "dataType": "json",
          "data": data,
          success: function(json,status){
            console.log(json);
            bt_refresh.element.trigger('dcmgrGUI.refresh');
          }
        });
       $(this).dialog("close");
      }
    }
  });

  var bt_delete_volume = new DcmgrGUI.Dialog({
    target:'.delete_volume',
    width:400,
    height:200,
    title:'Delete Volume',
    path:'/delete_volume',
    button:{
     "Close": function() { $(this).dialog("close"); },
     "Yes, Delete": function() { 
       var delete_volumes = $(this).find('#delete_volumes').find('li');
       var ids = []
       $.each(delete_volumes,function(){
         ids.push($(this).text())
       })
       
       var data = $.param({ids:ids})
       $.ajax({
          "type": "DELETE",
          "async": true,
          "url": '/volumes/delete',
          "dataType": "json",
          "data": data,
          success: function(json,status){
            console.log(json);
            bt_refresh.element.trigger('dcmgrGUI.refresh');
          }
        });
       c_list.changeStatus('deleting');
       $(this).dialog("close");
      }
    }
  });
  
  var bt_create_snapshot = new DcmgrGUI.Dialog({
    target:'.create_snapshot',
    width:400,
    height:200,
    title:'Create Snapshot',
    path:'/create_snapshot',
    button:{
     "Create": function() { 
       var volume_snapshots = $(this).find('#create_snapshots').find('li');
       var ids = []
       $.each(volume_snapshots,function(){
         ids.push($(this).text())
       })

       var data = $.param({ids:ids})
       $.ajax({
          "type": "POST",
          "async": true,
          "url": '/snapshots/create',
          "dataType": "json",
          "data": data,
          success: function(json,status){
            console.log(json);
            bt_refresh.element.trigger('dcmgrGUI.refresh');
          }
        });
       $(this).dialog("close");
      }
    }
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

  bt_refresh.element.bind('dcmgrGUI.refresh',function(){
    c_list.page = c_pagenate.current_page;
    list_request.url = DcmgrGUI.Util.getPagePath('/volumes/list/',c_list.page);
    list_request.data = DcmgrGUI.Util.getPagenateData(c_list.page,c_list.maxrow)
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

  //list
  c_list.setData(null);
  c_list.update(list_request,true);  
}