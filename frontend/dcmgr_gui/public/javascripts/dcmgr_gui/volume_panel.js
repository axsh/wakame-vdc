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
  
  var bt_create_volume = new DcmgrGUI.Dialog({
    target:'.create_volume',
    width:400,
    height:200,
    title:'Create Volume',
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
              bt_create_volume.disabledButton('Create',false);
            } else {
              bt_create_volume.disabledButton('Create',true);    
            }
          });
          
          if( $(self).find('#volume_size').val() ) {
            bt_create_volume.disabledButton('Create',false);
          }
        }
      });
    },
    button:{
     "Create": function() { 
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
    }
  });
  
  bt_create_volume.element.bind('dialogopen',function(){  
    bt_create_volume.disabledButton('Create',true);    
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
          "url": '/snapshots',
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

  var bt_attach_volume = new DcmgrGUI.Dialog({
	  target:'.attach_volume',
	  width:400,
	  height:200,
	  title:'Attach Volume',
	  path:'/attach_volume',
	  button:{
	      "Close": function() { $(this).dialog("close"); },
	      "Yes, Attach": function() {
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
	  }
  });

  var bt_detach_volume = new DcmgrGUI.Dialog({
    target:'.detach_volume',
    width:400,
    height:200,
    title:'Detach Volume',
    path:'/detach_volume',
    button:{
     "Close": function() { $(this).dialog("close"); },
     "Yes, Detach": function() { 
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
  
  dcmgrGUI.notification.subscribe('checked_box', bt_delete_volume, 'enable_button');
  dcmgrGUI.notification.subscribe('checked_box', bt_create_snapshot, 'enable_button');
  dcmgrGUI.notification.subscribe('unchecked_box', bt_delete_volume, 'disable_button');
  dcmgrGUI.notification.subscribe('unchecked_box', bt_create_snapshot, 'disable_button');
  dcmgrGUI.notification.subscribe('change_pagenate', bt_delete_volume, 'disable_button');
  dcmgrGUI.notification.subscribe('change_pagenate', bt_create_snapshot, 'disable_button');
  
  $(bt_create_volume.target).button({ disabled: false });
  $(bt_delete_volume.target).button({ disabled: true });
  $(bt_create_snapshot.target).button({ disabled: true });
  $(bt_refresh.target).button({ disabled: false });
  
  //list
  c_list.setData(null);
  c_list.update(list_request,true);  
}