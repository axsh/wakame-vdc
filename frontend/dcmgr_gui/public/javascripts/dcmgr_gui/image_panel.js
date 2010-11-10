DcmgrGUI.prototype.imagePanel = function(){
  var total = 0;
  var maxrow = 10;
  var page = 1;
  var list_request = { 
    "url":DcmgrGUI.Util.getPagePath('/images/list/',page),
    "data" : DcmgrGUI.Util.getPagenateData(page,maxrow)
  }
  
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
  var c_pagenate = new DcmgrGUI.Pagenate({
    row:maxrow,
    total:total
  });
  
  var c_list = new DcmgrGUI.List({
    element_id:'#display_images',
    template_id:'#imagesListTemplate',
    maxrow:maxrow,
    page:page
  });
      
  c_list.setDetailTemplate({
    template_id:'#imagesDetailTemplate',
    detail_path:'/images/show/'
  });
  
  c_list.element.bind('dcmgrGUI.contentChange',function(event,params){
    var image = params.data.image;
    c_pagenate.changeTotal(image.owner_total);
    c_list.setData(image.results);
    c_list.singleCheckList(c_list.detail_template);
  });
  
  var bt_refresh  = new DcmgrGUI.Refresh();
  
  bt_refresh.element.bind('dcmgrGUI.refresh',function(){
    c_list.page = c_pagenate.current_page;
    list_request.url = DcmgrGUI.Util.getPagePath('/images/list/',c_pagenate.current_page);
    list_request.data = DcmgrGUI.Util.getPagenateData(c_list.page,c_list.maxrow)
    c_list.element.trigger('dcmgrGUI.updateList',{request:list_request})
    
    //update detail
    $.each(c_list.checked_list,function(check_id,obj){
     
     //remove
     $($('#detail').find('#'+check_id)).remove();
     
     //update
     c_list.checked_list[check_id].c_detail.update({
       url:DcmgrGUI.Util.getPagePath('/images/show/',check_id)
     },true);
    });
  });
  
  c_pagenate.element.bind('dcmgrGUI.updatePagenate',function(){
    c_list.clearCheckedList();
    $('#detail').html('');
    bt_refresh.element.trigger('dcmgrGUI.refresh');
  });
  
  var bt_launch_instance = new DcmgrGUI.Dialog({
    target:'.launch_instance',
    width:583,
    height:600,
    title:'Launch Instance',
    path:'/launch_instance',
    callback: function(){

      var data = [];

      $.ajax({
        "type": "GET",
        "async": false,
        "url": '/security_groups/all.json',
        "dataType": "json",
        "data": "",
        success: function(json,status){
          var results = json.netfilter_group.results;
          var size = results.length
          for (var i=0; i < size ; i++) {
            data.push({
              "id" : results[i].result.uuid,
              "name" : results[i].result.name
            });
          }
        }
      });
              
      var security_group = new DcmgrGUI.ItemSelector({
        'left_select_id' : '#left_select_list',
        'right_select_id' : "#right_select_list",
        "data" : data
      });
      
      $(this).find('#right_button').click(function(){
        security_group.leftToRight();
      });

      $(this).find('#left_button').click(function(){
        security_group.rightToLeft();
      });
      
    },
    button:{
     "Launch": function() { 
       var image_id = $(this).find('#image_id').val();
       var host_pool_id = $(this).find('#host_pool_id').val();
       var instance_spec = $(this).find('#instance_spec').val();
       var data = "image_id="+image_id
                  +"&host_pool_id="+host_pool_id
                  +"&instance_spec="+instance_spec;
       $.ajax({
         "type": "POST",
         "async": true,
         "url": '/instances/create',
         "dataType": "json",
         "data": data,
         success: function(json,status){
           console.log(json);
         }
       });
       $(this).dialog("close");
      }
    }
  });
  
  bt_launch_instance.target.bind('click',function(){
    var id = c_list.currentChecked();
    if( id ){
      bt_launch_instance.open({"ids":[id]});
    }
    return false;
  });

  //list
  c_list.setData(null);
  c_list.update(list_request,true);
}