DcmgrGUI.prototype.imagePanel = function(){
  DcmgrGUI.List.prototype.getEmptyData = function(){
    return [{
      "id":'',
      "wmi_id":'',
      "source":'',
      "owner":'',
      "visibility":'',
      "state":''
    }]
  }
  
  DcmgrGUI.Detail.prototype.getEmptyData = function(){
        return {
            "name" : "-",
            "description" : "-",
            "source" : "-",
            "owner" : "-",
            "visibility" : "-",
            "product_code" : "-",
            "state" : "-",
            "karnel_id":"-",
            "platform" : "-",
            "root_device_type":"-",
            "root_device":"-",
            "image_size":"-",
            "block_devices":"-",
            "virtualization":"",
            "state_reason":"-"
          }
      }
      
  var list_request = { "url":DcmgrGUI.Util.getPagePath('/images/show/',1) }
  var c_list = new DcmgrGUI.List({
    element_id:'#display_images',
    template_id:'#imagesListTemplate'
  });
      
  c_list.setDetailTemplate({
    template_id:'#imagesDetailTemplate',
    detail_path:'/images/detail/'
  });
  

  var c_pagenate = new DcmgrGUI.Pagenate({
    row:10,
    total:30 //todo:get total from dcmgr
  });
  
  var bt_refresh  = new DcmgrGUI.Refresh();
  
  bt_refresh.element.bind('dcmgrGUI.refresh',function(){
    list_request.url = DcmgrGUI.Util.getPagePath('/images/show/',c_pagenate.current_page);
    c_list.element.trigger('dcmgrGUI.updateList',{request:list_request})
    
    //update detail
    $.each(c_list.checked_list,function(check_id,obj){
     
     //remove
     $($('#detail').find('#'+check_id)).remove();
     
     //update
     c_list.checked_list[check_id].c_detail.update({
       url:DcmgrGUI.Util.getPagePath('/images/detail/',check_id)
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