DcmgrGUI.prototype.imagePanel = function(){
  var total = 0;
  var maxrow = 10;
  var page = 1;
  var list_request = { 
    "url":DcmgrGUI.Util.getPagePath('/machine_images/list/',page),
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
  
  var close_button_name = $.i18n.prop('close_button'); 
  var launch_button_name = $.i18n.prop('launch_button');
  
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
    detail_path:'/machine_images/show/'
  });
  
  c_list.element.bind('dcmgrGUI.contentChange',function(event,params){
    var image = params.data.image;
    c_pagenate.changeTotal(image.total);
    c_list.setData(image.results);
    c_list.singleCheckList(c_list.detail_template);
  });
  
  var bt_refresh  = new DcmgrGUI.Refresh();
  
  bt_refresh.element.bind('dcmgrGUI.refresh',function(){
    c_list.page = c_pagenate.current_page;
    list_request.url = DcmgrGUI.Util.getPagePath('/machine_images/list/',c_pagenate.current_page);
    list_request.data = DcmgrGUI.Util.getPagenateData(c_pagenate.start,c_pagenate.row);
    c_list.element.trigger('dcmgrGUI.updateList',{request:list_request})
    
    //update detail
    $.each(c_list.checked_list,function(check_id,obj){
     
     //remove
     $($('#detail').find('#'+check_id)).remove();
     
     //update
     c_list.checked_list[check_id].c_detail.update({
       url:DcmgrGUI.Util.getPagePath('/machine_images/show/',check_id)
     },true);
    });
  });
  
  c_pagenate.element.bind('dcmgrGUI.updatePagenate',function(){
    c_list.clearCheckedList();
    $('#detail').html('');
    bt_refresh.element.trigger('dcmgrGUI.refresh');
  });
  
  var launch_instance_buttons = {};
  launch_instance_buttons[close_button_name] = function() { $(this).dialog("close"); };  
  launch_instance_buttons[launch_button_name] = function() {
    var image_id = $(this).find('#image_id').val();
    var host_node_id = $(this).find('#host_node').find('option:selected').val();
    var host_name = $(this).find('#host_name').val();
    var instance_spec_id = $(this).find('#instance_specs').val();
    var ssh_key_pair = $(this).find('#ssh_key_pair').find('option:selected').text();
    var launch_in = $(this).find('#right_select_list').find('option');
    var user_data = $(this).find('#user_data').val();
    var security_groups = [];
    $.each(launch_in,function(i){
     security_groups.push("security_groups[]="+ $(this).text());
    });

    var data = "image_id="+image_id
              +"&host_node_id="+host_node_id
              +"&instance_spec_id="+instance_spec_id
              +"&host_name="+host_name
              +"&user_data="+user_data
              +"&" + security_groups.join('&')
              +"&ssh_key="+ssh_key_pair;
    
    request = new DcmgrGUI.Request;
    request.post({
      "url": '/instances',
      "data": data,
      success: function(json,status){
       bt_refresh.element.trigger('dcmgrGUI.refresh');
      }
    });
    $(this).dialog("close");
  }
  
  var bt_launch_instance = new DcmgrGUI.Dialog({
    target:'.launch_instance',
    width:583,
    height:600,
    title:$.i18n.prop('launch_instance_header'),
    path:'/launch_instance',
    callback: function(){
      var self = this;
      
      var loading_image = DcmgrGUI.Util.getLoadingImage('boxes');
      $(this).find('#select_host_node').empty().html(loading_image);
      $(this).find('#select_ssh_key_pair').empty().html(loading_image);
      $(this).find("#left_select_list").mask($.i18n.prop('loading_parts'));
      
      var request = new DcmgrGUI.Request;
      var is_ready = {
        'host_node': false,
        'instance_spec': false,
        'ssh_keypair': false,
        'security_groups': false
      };

      var ready = function(data) {
        if(data['host_node'] == true &&
           data['instance_spec'] == true &&
           data['ssh_keypair'] == true &&
           data['security_groups'] == true) {  
          bt_launch_instance.disabledButton(1, false);
        } else {
          bt_launch_instance.disabledButton(1, true);
        }
      }
 
      parallel({
        //get host_nodes
        host_nodes: 
          request.get({
            "url": '/host_nodes/show_host_nodes.json',
            success: function(json,status){
              var select_html = '<select id="host_node" name="host_node"></select>';
              $(self).find('#select_host_node').empty().html(select_html);
              
              var results = json.host_node.results;
              var size = results.length;
              var select_host_node = $(self).find('#host_node');
              for (var i=0; i < size ; i++) {
                if(results[i].result.status == 'online') {
                  is_ready['host_node'] = true;
                  var uuid = results[i].result.uuid;
                  var html = '<option value="'+ uuid +'">'+uuid+'</option>';
                  select_host_node.append(html);
                }
              }
            }
          }),
        //get instance_specs
        instance_specs: 
          request.get({
            "url": '/instance_specs/all.json',
            success: function(json,status){
              var select_html = '<select id="instance_specs" name="instance_specs"></select>';
              $(self).find('#select_instance_specs').empty().html(select_html);

              var results = json.instance_spec.results;
              var size = results.length;
              var select_instance_specs = $(self).find('#instance_specs');
              if(size > 0) { 
                is_ready['instance_spec'] = true;
              }

              for (var i=0; i < size ; i++) {
                var uuid = results[i].result.uuid;
                var html = '<option value="'+ uuid +'">'+uuid+'</option>';
                select_instance_specs.append(html);
              }
            }
          }),
        //get ssh key pairs
        ssh_keypairs: 
          request.get({
            "url": '/keypairs/all.json',
            "data": "",
            success: function(json,status){
              var select_html = '<select id="ssh_key_pair" name="host_node"></select>';
              $(self).find('#select_ssh_key_pair').empty().html(select_html);

              var results = json.ssh_key_pair.results;
              var size = results.length;
              var select_keypair = $(self).find('#ssh_key_pair');
              if(size > 0) {
                is_ready['ssh_keypair'] = true;
              }

              for (var i=0; i < size ; i++) {
                var ssh_keypair_id = results[i].result.id;
                var html = '<option id="'+ ssh_keypair_id +'" value="'+ ssh_keypair_id +'">'+ssh_keypair_id+'</option>'
                select_keypair.append(html);
              }
            }
        }),
        //get security groups
        security_groups: 
          request.get({
            "url": '/security_groups/all.json',
            "data": "",
            success: function(json,status){
              var data = [];
              var results = json.security_group.results;
              var size = results.length;
              for (var i=0; i < size ; i++) {
                data.push({
                  "value" : results[i].result.uuid,
                  "name" : results[i].result.uuid,
                });
              }

              var security_group = new DcmgrGUI.ItemSelector({
                'left_select_id' : '#left_select_list',
                'right_select_id' : "#right_select_list",
                "data" : data,
                'target' : self
              });
              
              var on_ready = function(size){
                if(size > 0) {
                  is_ready['security_groups'] = true;
                  ready(is_ready);
                } else {
                  is_ready['security_groups'] = false;
                  ready(is_ready);
                }
              }

              $(self).find('#right_button').click(function(){
                security_group.leftToRight();
                on_ready(security_group.getRightSelectionCount());
              });

              $(self).find('#left_button').click(function(){
                security_group.rightToLeft();
                on_ready(security_group.getRightSelectionCount());
              });
            }
          })
      }).next(function(results) {
        $("#left_select_list").unmask();
      });
    },
    button: launch_instance_buttons
  });
  
  bt_launch_instance.target.bind('click',function(){
    var id = c_list.currentChecked();
    if( id ){
      bt_launch_instance.open({"ids":[id]});
      bt_launch_instance.disabledButton(1, true);
    }
    return false;
  });
  
  $(bt_launch_instance.target).button({ disabled: false });
  $(bt_refresh.target).button({ disabled: false });
  //list
  c_list.setData(null);
  c_list.update(list_request,true);
}
