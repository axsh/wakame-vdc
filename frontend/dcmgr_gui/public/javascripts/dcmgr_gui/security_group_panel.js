DcmgrGUI.prototype.securityGroupPanel = function(){
  var list_request = { "url":DcmgrGUI.Util.getPagePath('/security_groups/show/',1) };
  
  DcmgrGUI.List.prototype.getEmptyData = function(){
    return [{
      "id":'',
      "group_id":'',
      "name":'',
      "description":''
    }]
  }
  
  
  DcmgrGUI.Detail.prototype.getEmptyData = function(){
    return {
      "group_id":"-",
      "name" : "-",
      "description" : "-",
      "config" : "",
    }
  }
  
  DcmgrGUI.Detail.prototype.register_event('dcmgrGUI.configUpdate',function(event,id){

    var initialize_config = ""
    + "# Format\n"
    + "# Connection Method,Protocol,From Port,To Port,Source(IP or group)\n"
    + "#\n"
    + "# Exmaple:\n"
    + "# ssh,tcp,22,22,0.0.0.0/0\n";
    
    var data = $('#detail').find('#config_'+id).html();
    if(!data){
      $('#security_group_config').html(initialize_config);
    }
  });
  
  DcmgrGUI.Detail.prototype.register_event('dcmgrGUI.afterUpdate',function(event,params){
    var self = params.self;
    $('#detail').find('#update_'+self.id).live('click',function(){
      $.ajax({
         "type": "POST",
         "async": true,
         "url": '/security_groups/config',
         "data":"id="+self.id,
         "dataType": "json",
         success: function(json,status){
           console.log(status);
         }
       });
    });
    
    self.element.trigger('dcmgrGUI.configUpdate',[self.id]);
  });
             
  var c_list = new DcmgrGUI.List({
    element_id:'#display_volumes',
    template_id:'#securityGroupsListTemplate'
  });
  
  c_list.setDetailTemplate({
    template_id:'#securityGroupsDetailTemplate',
    detail_path:'/security_groups/detail/'
  });
  
  c_list.element.bind('dcmgrGUI.contentChange',function(event,params){
    c_list.setData(params.data);
    c_list.singleCheckList(c_list.detail_template);
  });

  var c_pagenate = new DcmgrGUI.Pagenate({
    row:10,
    total:30 //todo:get total from dcmgr
  });
  
  var bt_refresh  = new DcmgrGUI.Refresh();

  bt_refresh.element.bind('dcmgrGUI.refresh',function(){
    
    //Update list element
    list_request.url = DcmgrGUI.Util.getPagePath('/security_groups/show/',c_pagenate.current_page);
    c_list.element.trigger('dcmgrGUI.updateList',{request:list_request})
    
    $.each(c_list.checked_list,function(check_id,obj){
      //All remove detail element
      $($('#detail').find('#'+check_id)).remove();
      
      //All reload detail element
      c_list.checked_list[check_id].c_detail.update({
        url:DcmgrGUI.Util.getPagePath('/security_groups/detail/',check_id)
      },true);
    });
  });
  
  c_pagenate.element.bind('dcmgrGUI.updatePagenate',function(){
    c_list.clearCheckedList();
    $('#detail').html('');
    bt_refresh.element.trigger('dcmgrGUI.refresh');
  });

  c_list.setData(null);
  c_list.update(list_request,true);
}