var DcmgrGUI = function(){};

//Refarence:http://wp.serpere.info/archives/1091
DcmgrGUI.Class = (function() {
  function subclass() {}
  return {
    create: function(parent) {
        function klass() {
          this.initialize.apply(this, arguments);
        }

        var index = 0;
        if(jQuery.isFunction(parent)) {
          index = 1;
          subclass.prototype = parent.prototype;
          klass.prototype = new subclass;
        }
        for(; index < arguments.length; ++index) {
            jQuery.extend(klass.prototype, arguments[index]);
        }
        return klass;
      }
    }
})();

DcmgrGUI.Pagenate = DcmgrGUI.Class.create({
  initialize: function(params) {
    this.element = $('#pagenate');
    this.total = params.total;
    this.page_count = Math.ceil(params['total'] / params['row']);
    this.current_page = 1;
    this.row = params['row'];
    this.view = $("#viewPagenate").text();
    $('.prev').bind("click",{obj: this},this.updatePage);
    $('.next').bind("click",{obj: this},this.updatePage);

    this.renderPagenate();
  },
  renderPagenate: function(){
    var html = this.current_page + ' to ' + this.page_count + ' of ' + this.page_count;
    $("#viewPagenate").html(html+' '+this.view);    
  },
  updatePage: function(event){

    var self = event.data.obj;
    var name = $(this).attr('class');
    
    if(self.current_page >= 1 && self.current_page < self.page_count) {
      if(name === 'next'){
        self.next_page = self.current_page +1;
        self.current_page = self.next_page;
      }
    }
    
    if(self.current_page > 1 && self.current_page <= self.page_count){
      if(name === 'prev'){
        self.prev_page = self.current_page -1;
        self.current_page = self.prev_page;
      }
    }
    self.renderPagenate();
    self.element.trigger('dcmgrGUI.updatePagenate');
  }
});

DcmgrGUI.Dialog = DcmgrGUI.Class.create({
  initialize: function(params) {
    this.target = $(params['target']);
    this.element = $('<div></div>')
    this.path_prefix = '/dialog';
    this.path = this.path_prefix + params['path'];
    this.width = params['width'];
    this.height = params['height'];
    this.title = params['title'];
    this.button = params['button'];
  },
  open: function(params){
    //multi select action
    if(params){
      if(params.ids.length == 0){
        return false;
      }
      this.create(params);
    }else{
      //new create action
      this.create();
    }
    this.content.dialog('open');
  },
  close: function(){
    this.content.dialog('close');
  },
  create: function(params){
    this.content = this.element
        .load(this.path,params)
  			.dialog({
  				title: this.title,
  				disable: false,
  				autoOpen: false,
  				bgiframe: true,
  				width: this.width,
  				height: this.height,
  				modal: true,
  				resizable: true,
  				closeOnEscape: true,
  				closeText: 'hide',
  				draggable:false,
  				buttons: this.button
  	});
  }
});

DcmgrGUI.ContentBase = DcmgrGUI.Class.create({
  initialize: function(params){
    this.id = params.id;
    this.element = $(params.element_id);
    this.template = params.template_id;
    this.events = this.events||[];
    
    //prototype.register_event function add to call before initialize function
    this.bind_events();
  },
  update:function(request,async){
    this.request = request;
    this.async = async;
    var self = this;
    self.element.trigger('dcmgrGUI.beforeUpdate');
    
    $.ajax({
       async: async||true,
       url: request.url,
       dataType: "json",
       success: function(json,status){
         self.element.trigger('dcmgrGUI.contentChange',[{"data":json,"self":self}]);
         self.element.trigger('dcmgrGUI.afterUpdate',[{"data":json,"self":self}]);
       }
     });
  },
  register_event:function(name,handler){
    this.events = this.events||[]
    this.events.push({
      "name":name,
      "handler":handler
    })
  },bind_events:function(){
    for(var i in this.events){
      this.element.bind(this.events[i].name,this.events[i].handler);
    }
  }
});

DcmgrGUI.Util = {};
DcmgrGUI.Util.getPagePath = function(path,page,format){
    var format = format||'json';
    return path + page + '.' + format;
}
DcmgrGUI.Util.setfillData = function(maxrows,json){
    var fillCount = maxrows-json.length;
    var emptyObj = [];
    for (var key in json[0]) {
      emptyObj.key = ''
    }
    for(var i=0;i<fillCount;i++){
      json.push(emptyObj);
    }
  return json;
}

DcmgrGUI.List = DcmgrGUI.Class.create(DcmgrGUI.ContentBase, {
  initialize: function(params){
    this.element = $(params.element_id);
    this.template = params.template_id;
    this.checked_list = {};
    this.detail_template = {};
    
    var self = this;
    this.element.bind('dcmgrGUI.contentChange',function(event,params){
      self.setData(params.data);
      self.checkList(self.detail_template);
    });
    
    this.element.bind('dcmgrGUI.afterUpdate',function(event){
      
      var bg;
      var kids;
      
      $("table").find('td').hover(
        function () {
         //Mouse over
         bg = $(this).parent().css("background-color");
         kids = $(this).parent().children();
         kids.css("background-color","#82c9d9");
        },
        function () {
         //Mouse over
         kids.css("background-color",bg);
        }
      );
      
      self.element.find("[type='checkbox']").each(function(key,value){
        var id = $(value).val();
        if(self.checked_list[id]){
          $(event.target).find("[type='checkbox']").each(function(){
            if($(this).val() === id){
              $(this).attr('checked',true);
            }
          })
        }
      })
    });
    
    this.element.bind('dcmgrGUI.updateList',function(event,params){
      self.update(params.request,true)
    });
    
  },
  setDetailTemplate:function(template){
    this.detail_template = template;
  },
  getCheckedInstanceIds:function(checked_list){
    var ids = []
    for(var id in this.checked_list){
      ids.push(id);
    }
    return { 
      'ids':ids 
    }
  },
  setData:function(json){
    if(!json){
      json = this.getEmptyData()
    }
    var row = this.element.find('tr').length-1;
    var data = {
      rows:DcmgrGUI.Util.setfillData(row,json)
    };
    
    this.element.html('');
    if(data.rows){
      $( this.template )
        .tmpl( data )
        .appendTo( this.element );
    }
  },
  clearCheckedList:function(){
    this.checked_list = {}
  },
  changeStatus:function(state){
    $.each(this.checked_list,function(id,obj){
       obj.element.find('.state').html(state);
       $('#detail').find('#'+id).find('.state').html(state);
    });
  },
  checkList:function(params){
    var self = this;
    this.element.find("[type='checkbox']").each(function(key,value){
      $(this).click(function(){
        var check_id = $(this).val();
        
        if($(this).is(':checked')){

          //step1:onclick checkbox and generate detail object
          self.checked_list[check_id] = {
            //+1 is to remove table header
            element:$(self.element.find('tr')[key+1]),
            c_detail:new DcmgrGUI.Detail({
              //id is to search element key
              id:check_id,
              element_id:$('<div></div>'),
              template_id:params.template_id
            })
          }
          
          //step2:bind event dcmgrGUI.contentChange
          self.checked_list[check_id].c_detail.element.bind('dcmgrGUI.contentChange',function(event,params){
            if(self.checked_list[check_id]){
            
              //step4:marge data in template
              var data = { item:params.data }
              
              //initialize
              if(!params.data){
                data.item = self.checked_list[check_id].c_detail.getEmptyData();
              }
              
              if(data.item){
                $( self.checked_list[check_id].c_detail.template )
                  .tmpl(data)
                  .appendTo( $('#detail') );
              }
            }
          });
          
          //step3:update detail
          self.checked_list[check_id].c_detail.update({
            url:DcmgrGUI.Util.getPagePath(params.detail_path,check_id)
          },true);

        }else{
          //remove detail
          if(self.checked_list[check_id]){
           $($('#detail').find('#'+check_id)).remove();
           delete self.checked_list[check_id]
         }
          
        }
      });
    })
  }
});

DcmgrGUI.Detail = DcmgrGUI.Class.create(DcmgrGUI.ContentBase, {
});

DcmgrGUI.Refresh = DcmgrGUI.Class.create({
  initialize: function(){
    this.element = $('.refresh');
    var self = this;
    self.element.live('click',function(){
      self.element.trigger('dcmgrGUI.refresh');
    })
  },
});

DcmgrGUI.prototype = {
  initialize:function(){
    $.deferred.define();
  },
  instancePanel:function(){
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
  },
  imagePanel:function(){
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
  },
  volumePanel:function(){
    var list_request = { "url":DcmgrGUI.Util.getPagePath('/volumes/show/',1) };
    
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
            "volume_id" : "-",
            "capacity" : "-",
            "snapshot" : "-",
            "created" : "-",
            "zone" : "-",
            "status" : "",
            "attachment_information" : "-"
          }
        }

    var c_list = new DcmgrGUI.List({
      element_id:'#display_volumes',
      template_id:'#volumesListTemplate'
    });
    
    c_list.setDetailTemplate({
      template_id:'#volumesDetailTemplate',
      detail_path:'/volumes/detail/'
    });

    var c_pagenate = new DcmgrGUI.Pagenate({
      row:10,
      total:30 //todo:get total from dcmgr
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
         var volume_size = $('#volume_size').val();
         var unit = $('#unit').find('option:selected').val();
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
         var delete_volumes = $('#delete_volumes').find('li');
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
            }
          });
         c_list.changeStatus('deleting');
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

    bt_refresh.element.bind('dcmgrGUI.refresh',function(){
      list_request.url = DcmgrGUI.Util.getPagePath('/volumes/show/',c_pagenate.current_page);
      c_list.element.trigger('dcmgrGUI.updateList',{request:list_request})
      
      //update detail
      $.each(c_list.checked_list,function(check_id,obj){
        $($('#detail').find('#'+check_id)).remove();
        c_list.checked_list[check_id].c_detail.update({
          url:DcmgrGUI.Util.getPagePath('/volumes/detail/',check_id)
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
    
  },
  securityGroupPanel:function(){
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
        $('#detail').find('#config_'+id).html(initialize_config);
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
      
      self.element.trigger('dcmgrGUI.configUpdatee',[self.id]);
    });
               
    var c_list = new DcmgrGUI.List({
      element_id:'#display_volumes',
      template_id:'#securityGroupsListTemplate'
    });
    
    c_list.setDetailTemplate({
      template_id:'#securityGroupsDetailTemplate',
      detail_path:'/security_groups/detail/'
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
}