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
    this.page_count = this.getPageCount(params['total'],params['row']);
    this.current_page = 1;
    this.row = params['row'];
    this.view = $("#viewPagenate").text();
    $('.prev').bind("click",{obj: this},this.updatePage);
    $('.next').bind("click",{obj: this},this.updatePage);

    this.renderPagenate();
  },
  getPageCount: function(total,row){
    return Math.ceil(total / row)
  },
  changeTotal: function(total){
    this.total = total;
    this.page_count = this.getPageCount(this.total,this.row)
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
    this.callback = params['callback'] ||null;
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
        .load(this.path,params,this.callback)
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

    $("#list_load_mask").mask("Loading...");
    self.element.trigger('dcmgrGUI.beforeUpdate');
    $.ajax({
       async: async||true,
       url: request.url,
       dataType: "json",
       data: request.data,
       success: function(json,status,xhr){
         self.element.trigger('dcmgrGUI.contentChange',[{"data":json,"self":self}]);
         self.element.trigger('dcmgrGUI.afterUpdate',[{"data":json,"self":self}]);
         $("#list_load_mask").unmask();
       },
       error: function(xhr, status, error){
         $("#list_load_mask").unmask();
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

DcmgrGUI.Util.getPagenateData = function(page,limit){

  if (page === 1) {
    var start = 1;
  } else {
    var start = ((page -1) * limit) + 1;
  }
  
  return "start=" + start + "&" + "limit=" + limit;
}

DcmgrGUI.List = DcmgrGUI.Class.create(DcmgrGUI.ContentBase, {
  initialize: function(params){
    this.element = $(params.element_id);
    this.template = params.template_id;
    this.checked_list = {};
    this.detail_template = {};
    this.maxrow = params.maxrow
    this.page = params.page
    
    var self = this;

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
  checkRadioButton:function(id){
    $('#'+id).attr("checked", true);
  },
  setData:function(json){
    var rows = []
    if(!json){
      rows = this.getEmptyData()
    }else{
      $.each(json,function(key,value){
        rows.push(value.result)
      });
    }
    var row = this.maxrow || 10;
    var data = {
      rows:DcmgrGUI.Util.setfillData(row,rows)
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
  currentChecked:function(){
    var id = this.element.find("[type='radio']:checked").val();
    if( id ){
      return id;
    }else{
      return null;
    }
  },
  singleCheckList:function(params){
    var self = this;
    this.element.find("[type='radio']").each(function(key,value){
      $(this).click(function(){
        var check_id = $(this).val();
        
        if($(this).is(':checked')){
          var c_detail = new DcmgrGUI.Detail({
            element_id:$('<div></div>'),
            template_id:params.template_id
          });
          
          c_detail.element.bind('dcmgrGUI.contentChange',function(event,params){
            var data = { item:params.data }
            
            //initialize
            if(!params.data){
              data.item = self.getEmptyData();
            }
            
            if(data.item){
              $('#detail').html($( c_detail.template ).tmpl(data));
            }
          });
          
          c_detail.update({
            url:DcmgrGUI.Util.getPagePath(params.detail_path,check_id)
          },true);
          
        }else{
          $('#detail').html('');
        }
      });
    });
  },
  multiCheckList:function(params){
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

DcmgrGUI.ItemSelector = DcmgrGUI.Class.create({
  
  initialize: function(params) {

    this.left_select_id = params.left_select_id;
    this.right_select_id = params.right_select_id;
    this.data = params.data;
    
    this.leftSelectionsArray = [];
    var dataSize = this.data.length;
    for(var i = 0;i < dataSize ;i++) {
      var html = '<option id="'+i+'" value="'+ this.data[i]['value'] +'">'+ this.data[i]['name'] +'</option>';
      this.leftSelectionsArray[i] = $(html);
    }
    this.rightSelectionsArray = this.emptyArray(this.data.length);
    
    this.refreshOptions(this.left_select_id,this.leftSelectionsArray);
  },
  refreshOptions: function(select_id,selectionsArray){
    var selectionsSize = selectionsArray.length;
    $(select_id).html('');
    for(var i = 0;i < selectionsSize  ;i++) {
      if(selectionsArray[i] !== null ){
        $(select_id).append(selectionsArray[i]);
      }
    }
  },
  emptyArray: function(size) {
    var data = [];
    for(var i = 0;i < size  ;i++) {
      data[i] = null;
    }
    return data;
  },
  leftToRight: function() {
    var self = this;
    $(this.left_select_id).find('option:selected').each(function(){
      var index = $(this).attr('id');
      self.leftSelectionsArray[index] = null;
      self.rightSelectionsArray[index] = this;
      $(this).remove();
    });
    
    this.refreshOptions(this.right_select_id,this.rightSelectionsArray);
  },
  rightToLeft: function() {
    var self = this;
    $(this.right_select_id).find('option:selected').each(function(){
      var index = $(this).attr('id');
      self.leftSelectionsArray[index] = this;
      self.rightSelectionsArray[index] = null;
      $(this).remove();
    });
    
    this.refreshOptions(this.left_select_id,this.leftSelectionsArray);
  }
});

DcmgrGUI.prototype = {
  initialize:function(){
    $.deferred.define();
  }
}