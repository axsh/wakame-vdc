DcmgrGUI.prototype.securityGroupPanel = function(){
  
  var maxrow = 10;
  var page = 1;
  var list_request = { 
    "url" : DcmgrGUI.Util.getPagePath('/security_groups/list/',1),
    "data" : DcmgrGUI.Util.getPagenateData(page,maxrow)
  };
  
  DcmgrGUI.List.prototype.getEmptyData = function(){
    return [{
      "name":'',
      "description":''
    }]
  }
  
  
  DcmgrGUI.Detail.prototype.getEmptyData = function(){
    return {
      "name" : "-",
      "description" : "-",
      "rule":''
    }
  }
  
  var c_pagenate = new DcmgrGUI.Pagenate({
    row:maxrow,
    total:30 //todo:get total from dcmgr
  });
  
  var c_list = new DcmgrGUI.List({
    element_id:'#display_security_groups',
    template_id:'#securityGroupsListTemplate',
    maxrow:maxrow,
    page:page
  });
  
  c_list.setDetailTemplate({
    template_id:'#securityGroupsDetailTemplate',
    detail_path:'/security_groups/show/'
  });
  
  c_list.element.bind('dcmgrGUI.contentChange',function(event,params){
    c_list.page = c_pagenate.current_page;
    c_list.setData(params.data);
    c_list.singleCheckList(c_list.detail_template);
  });
  
  var bt_refresh  = new DcmgrGUI.Refresh();

  bt_refresh.element.bind('dcmgrGUI.refresh',function(){
    
    //Update list element
    c_list.page = c_pagenate.current_page;
    list_request.url = DcmgrGUI.Util.getPagePath('/security_groups/list/',c_list.page);
    list_request.data = DcmgrGUI.Util.getPagenateData(c_list.page,c_list.maxrow)
    c_list.element.trigger('dcmgrGUI.updateList',{request:list_request})
    
    $.each(c_list.checked_list,function(check_id,obj){
      //All remove detail element
      $($('#detail').find('#'+check_id)).remove();
      
      //All reload detail element
      c_list.checked_list[check_id].c_detail.update({
        url:DcmgrGUI.Util.getPagePath('/security_groups/show/',check_id)
      },true);
    });
  });
  
  c_pagenate.element.bind('dcmgrGUI.updatePagenate',function(){
    c_list.clearCheckedList();
    $('#detail').html('');
    bt_refresh.element.trigger('dcmgrGUI.refresh');
  });
  
  var bt_create_security_group = new DcmgrGUI.Dialog({
    target:'.create_security_group',
    width:400,
    height:500,
    title:'Create Security Group',
    path:'/create_security_group',
    button:{
     "Create": function() { 
       var name = $('#security_group_name').val();
       var description = $('#security_group_description').val();
       var rule = $('#security_group_rule').val();
       var data = 'name=' + name
                 +'&description=' + description
                 +'&rule=' + rule;
       if(!name){
         $('#security_group_name').focus();
         return false;
       }

       if(!description){
         $('#security_group_description').focus();
         return false;
       }

       if(!rule){
         $('#security_group_rule').focus();
         return false;
       }
       
       $('#security_group_name').focus();

       $.ajax({
          "type": "POST",
          "async": true,
          "url": '/security_groups.json',
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
  
  bt_create_security_group.target.bind('click',function(){
    bt_create_security_group.open();
  });
  
  var bt_delete_security_group = new DcmgrGUI.Dialog({
    target:'.delete_security_group',
    width:400,
    height:200,
    title:'Delete Security Group',
    path:'/delete_security_group',
    button:{
     "Yes, Delete": function() { 
       var name = $('#delete_group_name').text();
       $.ajax({
          "type": "DELETE",
          "async": true,
          "url": '/security_groups/'+ name +'.json',
          "dataType": "json",
          success: function(json,status){
            console.log(json);
            bt_refresh.element.trigger('dcmgrGUI.refresh');
          }
       });
       $(this).dialog("close");
      }
    }
  });
  
  bt_delete_security_group.target.bind('click',function(){
    var id = c_list.currentChecked();
    if( id ){
      bt_delete_security_group.open(id);
    }
    return false;
  });

  c_list.setData(null);
  c_list.update(list_request,true);
}