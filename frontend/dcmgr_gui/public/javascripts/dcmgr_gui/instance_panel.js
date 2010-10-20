DcmgrGUI.prototype.instancePanel = function(){
  DcmgrGUI.List.prototype.getEmptyData = function(){
    return [{
      "id":'',
      "instance_id":'',
      "owner":'',
      "wmi_id":'',
      "state":'',
      "private_ip":'',
      "type":''
    }]
  }
  
  DcmgrGUI.Detail.prototype.getEmptyData = function(){
    return {
      "instance_id":'-',
      "wmi_id":'-',
      "zone":'-',
      "security_groups":'-',
      "type":'-',
      "status":'-',
      "owner":'-'
    }
  }
  
  var list_request = { "url":DcmgrGUI.Util.getPagePath('/instances/show/',1) };

  var c_list = new DcmgrGUI.List({
    element_id:'#display_instances',
    template_id:'#instancesListTemplate'
  });
  
  c_list.setDetailTemplate({
    template_id:'#instancesDetailTemplate',
    detail_path:'/instances/detail/'
  });

  var c_pagenate = new DcmgrGUI.Pagenate({
    row:10,
    total:30 //todo:get total from dcmgr
  });
  
  var bt_refresh  = new DcmgrGUI.Refresh();
    
  var bt_instance_start = new DcmgrGUI.Dialog({
    target:'.start_instances',
    width:400,
    height:200,
    title:'Start Instances',
    path:'/start_instances',
    button:{
     "Close": function() { $(this).dialog("close"); },
     "Yes, Start": function() { 
       c_list.changeStatus('starting');
       $(this).dialog("close");
      }
    }
  });
  
  var bt_instance_stop = new DcmgrGUI.Dialog({
     target:'.stop_instances',
     width:400,
		 height:200,
		 title:'Stop Instances',
		 path:'/stop_instances',
		 button:{
			"Close": function() { $(this).dialog("close"); },
			"Yes, Stop": function() {
			  c_list.changeStatus('stopping');
			  $(this).dialog("close");
			}
		}
  });
  
  var bt_instance_reboot = new DcmgrGUI.Dialog({
     target:'.reboot_instances',
     width:400,
		 height:200,
		 title:'Reboot Instances',
		 path:'/reboot_instances',
		 button:{
		  "Close": function() { $(this).dialog("close"); },
			"Yes, Reboot": function() {
			  c_list.changeStatus('rebooting');
			  $(this).dialog("close");
			}
		}
  });
  
  var bt_instance_terminate = new DcmgrGUI.Dialog({
    target:'.terminate_instances',
    width:400,
    height:200,
    title:'Terminate Instances',
    path:'/terminate_instances',
    button:{
		  "Close": function() { $(this).dialog("close"); },
			"Yes, Terminate": function() {
			  c_list.changeStatus('terminating');
			  $(this).dialog("close");
			}
    }
  });
  
  bt_instance_start.target.bind('click',function(){
    bt_instance_start.open(c_list.getCheckedInstanceIds());
  });

  bt_instance_stop.target.bind('click',function(){
    bt_instance_stop.open(c_list.getCheckedInstanceIds());
  });

  bt_instance_reboot.target.bind('click',function(){
    bt_instance_reboot.open(c_list.getCheckedInstanceIds());
  });

  bt_instance_terminate.target.bind('click',function(){
    bt_instance_terminate.open(c_list.getCheckedInstanceIds());
  });
  
  bt_refresh.element.bind('dcmgrGUI.refresh',function(){
    list_request.url = DcmgrGUI.Util.getPagePath('/instances/show/',c_pagenate.current_page);
    c_list.element.trigger('dcmgrGUI.updateList',{request:list_request})
    
    //update detail
    $.each(c_list.checked_list,function(check_id,obj){
      
      //todo:remove trigger event for detail
      $($('#detail').find('#'+check_id)).remove();
      
      //todo:update trigger event for detail
      c_list.checked_list[check_id].c_detail.update({
        url:DcmgrGUI.Util.getPagePath('/instances/detail/',check_id)
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