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

DcmgrGUI.Request = DcmgrGUI.Class.create({
  initialize: function(){
    dcmgrGUI.setConfig('error_popup', true);
  },
  get: function(params){
    params['type'] = 'GET';
    return this._request(params);
  },
  put: function(params){
    params['type'] = 'PUT';
    return this._request(params);
  },
  post: function(params){
    params['type'] = 'POST';
    return this._request(params);
  },
  del: function(params){
    params['type'] = 'DELETE';
    return this._request(params);
  },

  _request: function(params){
    params['async'] = params['async'] || true;
    params['dataType'] = 'json';
    params['cache'] = false;
    return $.ajax(params);
  }
});
  
DcmgrGUI.Filter = DcmgrGUI.Class.create({
  initialize: function(){
    this.filters = [];
  },
  add: function(filter){
    this.filters.push(filter);
  },
  execute: function(data){
    this.apply(0,data);
  },
  apply: function(index,data){
    if (this.filters[index] && typeof this.filters[index] === "function") {
      this.filters[index](data);
      var next_index = index + 1;
      if (this.filters[next_index]) {
        this.apply(next_index,data);
      } else {
        return data;
      }
    }
  }
});

DcmgrGUI.Converter = {};

// Convert number to default display byte unit (GB).
displayByteUnit = DcmgrGUI.Converter.toDisplayByteUnit = function(qty, unit) {
  var q;
  if (qty === undefined || qty == ''){
    return "";
  }else if(typeof qty === 'number'){
    qty=qty/1024/1024/1024;
    if (unit === undefined ){ unit = ' byte'; }
    q = new Qty(qty + unit);
  }else{
    if (unit !== undefined ){ qty = qty + unit; }
    q = new Qty(qty);
  }
  return q.toPrec('0.01 GB').toString('GB');
};

DcmgrGUI.Converter.unit = function(data, unit_type){
  var unit = '';
  switch(unit_type) {
    case 'megabyte':
      unit = 'MB';
    break;

    case 'gigabyte':
      unit = 'GB';
    break;
  }
  return  data + unit;
};

DcmgrGUI.date = {};
DcmgrGUI.date.parseISO8601 = function (str) {
  /*
   Reference: http://anentropic.wordpress.com/2009/06/25/javascript-iso8601-parser-and-pretty-dates/
  */
  
  // we assume str is a UTC date ending in 'Z'
  var parts = str.split('T'),
  dateParts = parts[0].split('-'),
  timeParts = parts[1].split('Z'),
  timeSubParts = timeParts[0].split(':'),
  timeSecParts = timeSubParts[2].split('.'),
  timeHours = Number(timeSubParts[0]),
  _date = new timezoneJS.Date();

  _date.setUTCFullYear(Number(dateParts[0]));
  _date.setUTCMonth(Number(dateParts[1] - 1 ));
  _date.setUTCDate(Number(dateParts[2]));
  _date.setUTCHours(Number(timeHours));
  _date.setUTCMinutes(Number(timeSubParts[1]));
  _date.setUTCSeconds(Number(timeSecParts[0]));
  if (timeSecParts[1]) _date.setUTCMilliseconds(Number(timeSecParts[1]));

  // by using setUTC methods the date has already been converted to local time(?)
  return _date;
};

DcmgrGUI.date.setTimezone = function(date_str, timezone){
  date_str.setTimezone(timezone);
  return date_str;
};

DcmgrGUI.date.setTimezoneOffset = function(date_str, utc_offset){
  date_str.setUTCSeconds(utc_offset);
  return date_str;
};

DcmgrGUI.date.getI18n = function(date_str){

  var convert = function(value) {
    return ("0" + value).slice(-2);
  }

  return $.i18n.prop('display_date', [date_str.getUTCFullYear(), 
                                   convert(date_str.getMonth() + 1), 
                                   convert(date_str.getDate()), 
                                   convert(date_str.getHours()), 
                                   convert(date_str.getMinutes()), 
                                   convert(date_str.getSeconds())
                                   ]);
};

// Convert UTC ISO8601 time string to local TZ with I18n.
DcmgrGUI.date.utcToLocal = function(iso8601_date_str) {
  // TODO: cleanup white spaces in date_str.
  try {
    return DcmgrGUI.date.getI18n(DcmgrGUI.date.setTimezone(DcmgrGUI.date.parseISO8601(iso8601_date_str),
                                                           dcmgrGUI.getConfig('time_zone')
                                                          ));
  } catch(a) {
    return iso8601_date_str;
  }
};
      

DcmgrGUI.Pagenate = DcmgrGUI.Class.create({
  initialize: function(params) {
    var self = this;
    this.element = $('#pagenate');
    this.view = $("#viewPagenate").text();
    this.total = params.total;
    this.page_count = this.getPageCount(params['total'],params['row']);
    this.current_page = 1;
    this.row = params['row'];
    this.start = this.getStartCount();
    this.offset = this.getOffsetCount();
    this.prev = DcmgrGUI.Util.createUIButton(this.element.find('.prev'),{
      disabled : true,
      text : false
    });
    this.next = DcmgrGUI.Util.createUIButton(this.element.find('.next'),{
      disabled : true,
      text : false
    });
    
    this.prev.bind("click",{obj: this},function(event){
      var self = event.data.obj;
      if (self.prev.button("option","disabled")) { 
        return false;
      };

      self.updatePage.call(this,event);
      self.changeArrowButton();
    });
    
    this.next.bind("click",{obj: this},function(event){
      var self = event.data.obj;
      if (self.next.button("option","disabled")) { 
        return false;
      };
      
      self.updatePage.call(this,event);
      self.changeArrowButton();
    });

    this.renderPagenate();
    
    //create topics
    dcmgrGUI.notification.create_topic('change_pagenate');
  },
  changeArrowButton: function() {
    if (this.current_page === 1){
      this.prev.button("option", "disabled", true);
      this.next.button("option", "disabled", false);
    }else{
      if (this.current_page === this.page_count) {
        this.prev.button("option", "disabled", false);
        this.next.button("option", "disabled", true);
      } else {
        this.prev.button("option", "disabled", false);
        this.next.button("option", "disabled", false);
      }
    }
  },
  getPageCount: function(total,row){
    return Math.ceil(total / row);
  },
  changeTotal: function(total){
    this.total = total;
    
    if(this.total > (this.current_page * this.row)) {
      this.next.button("option", "disabled", false);
    }else{
      this.next.button("option", "disabled", true);
    }
    
    this.page_count = this.getPageCount(this.total,this.row)
    this.renderPagenate();
  },
  changePage: function() {
    var self = this;
    var current_page = $('#viewPagenate').find("#current_page");
    if(current_page.length != 0) {
      current_page.bind("focus", function(){
        this.select();
      });
      
      current_page.bind("keypress", function(event){
        if(event.keyCode == 13) {
          var page = parseInt(current_page.val());
          self.current_page = page;
          self.page = page;
          event.data = {'obj': self};
          self.updatePage.call(this, event);
          self.changeArrowButton();
        }
      });
    }
  },
  renderPagenate: function(){
    this.start = this.getStartCount();
    this.offset = this.getOffsetCount();
    if (this.start !== 0 && this.offset !==0 ) {
      var current_page = '<input type="text" id="current_page" style="width:20px;height:13px" value="'+ this.current_page +'">';
      var page = $.i18n.prop('page_pagenate', [this.page_count]);
      var total = $.i18n.prop('total_pagenate', [this.total]);
      var html = current_page + ' / ' + page + ' : ' + total;
      html += ' ' + this.view;
    } else{
      var html = '';
    }
    $("#viewPagenate").html(html);
    this.changePage();
  },
  updatePage: function(event){
    var self = event.data.obj;
    if($(this).attr('class')) {
      var name = $(this).attr('class').split(' ')[0];
    }

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
    dcmgrGUI.notification.publish('change_pagenate');
  },
  getOffsetCount: function(){
    var count = (this.current_page * this.row);
    
    if (this.total < count) {
      return this.total;
    } else {
      return count;
    }
  },
  getStartCount: function(){
    if (this.current_page === 1) {
      var start = 1;
    } else {
      var start = ((this.current_page -1) * this.row) + 1;
    }
    return start;
  }
});

DcmgrGUI.Dialog = DcmgrGUI.Class.create({
  initialize: function(params) {
    this.target = $(params['target']);
    this.element = $('<div></div>');
    this.path_prefix = '/dialog';
    this.path = this.path_prefix + params['path'];
    this.width = params['width'];
    this.height = params['height'];
    this.title = params['title'];
    this.button = params['button'];
    this.callback = params['callback'] ||null;
    dcmgrGUI.notification.create_topic('close_dialog');
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
  getWidgetButton: function(num) {
    var widget = $(this.content.dialog('widget')
                    .find(".ui-button-text")[num]);
    return widget;
  },
  disabledButton: function(num, disabled){
    var widget = this.getWidgetButton(num);
    if( widget ) {
      widget.parent().button("option", "disabled", disabled);
    }
  },
  close: function(){
    this.content.dialog('close');
  },
  enableDialogButton: function(){
    $(this.target).button({ disabled: false });
  },
  disableDialogButton: function(){
    $(this.target).button({ disabled: true });
  },
  is_disabled: function(){
    return $(this.target).button("option", "disabled");
  },
  create: function(params){
    //initialize
    this.element = $('<div></div>');
    
    this.content = this.element
                       .load(this.path + '?_=' + (new Date()).getTime(),
                             params,
                             this.callback)
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
                           buttons: this.button,
                           close: function(event, ui) {
                             dcmgrGUI.notification.publish('close_dialog');
                           }
                       });
  }
});

DcmgrGUI.ContentBase = DcmgrGUI.Class.create({
  initialize: function(params){
    if (params.element_id) {
      this.element = $(params.element_id);
    } else {
      this.element = $('<div></div>');
    }
    this.template = params.template_id;
    this.filter = new DcmgrGUI.Filter();
  },
  update:function(params,async){
    var self = this;
    try{
      $("#list_load_mask").mask($.i18n.prop('loading_parts'));
      self.element.trigger('dcmgrGUI.beforeUpdate');
      var request = new DcmgrGUI.Request;
      request.get({
        url: params.url,
        data: params.data,
        success: function(json,status,xhr){
          self.filter.execute(json);
          self.element.trigger('dcmgrGUI.contentChange',[{"data":json,"self":self}]);
          self.element.trigger('dcmgrGUI.afterUpdate',[{"data":json,"self":self}]);
        },
        complete: function(xhr, status) {
          $("#list_load_mask").unmask();
        }
      });
    } catch( e ) {
      console.log(e);
      $("#list_load_mask").unmask();
    }
  }
});

DcmgrGUI.Util = {};
DcmgrGUI.Util.getPagePath = function(path,page,format){
    var format = format||'json';
    return path + page + '.' + format;
};
DcmgrGUI.Util.setfillData = function(maxrows,json){
    var fillCount = maxrows-json.length;
    var emptyObj = [];
    for (var key in json[0]) {
      emptyObj.key = '';
    }
    for(var i=0;i<fillCount;i++){
      json.push(emptyObj);
    }
  return json;
};

DcmgrGUI.Util.getLoadingImage = function(type){
  switch(type) {
    case "ball":
      var image = 'loader_ball.gif';
    break;
    
    case "boxes":
      var image = 'loader_boxes.gif';
    break;
    
    default:
      var image = 'loader_ball.gif';
    break;
  }
  return '<img src="images/'+image+'" />';
};


DcmgrGUI.Util.getPagenateData = function(start,limit){
  return "start=" + start + "&" + "limit=" + limit;
};

DcmgrGUI.Util.createUIButton = function(element,options){
  return element
          .button(options)
          .removeClass("ui-state-default")
          .removeClass("ui-button")
          .removeClass("ui-corner-all")
          .hover(function(){
            element.removeClass("ui-state-hover");
          })
          .focus(function(){
            element.removeClass("ui-state-focus");
          });
};

DcmgrGUI.Util.availableTextField = function(e){

  var d = e.data;
  var button = d.button;
  var element_id = d.element_id;

  if(_.include(['paste', 'cut'], e.type)) {
    var el = $(this);
    setTimeout(function() {
      var text = $(el).val();
      if(text) {
        button.disabledButton(element_id, false);
      } else {
        button.disabledButton(element_id, true);
      }
    }, 100);       
  } else {
    var text = $(this).val();
    if(text) {
      button.disabledButton(element_id, false);
    } else {
      button.disabledButton(element_id, true);
    }
  }
  return true;
};

DcmgrGUI.Util.checkTextField = function(e) {
    var d = e.data;
    var name = d.name;
    var is_ready = d.is_ready;
    var ready = d.ready;

    if(_.include(['paste', 'cut'], e.type)) {
	var el = $(this);
	setTimeout(function(){
		var text = $(el).val();
		if(text) {
		    is_ready[name] = true;
		    ready(is_ready);
		} else {
		    is_ready[name] = false;
		    ready(is_ready);
		}
	    }, 100);
    } else {
	var text = $(this).val();
	if(text) {
	    is_ready[name] = true;
	    ready(is_ready);
	} else {
	    is_ready[name] = false;
	    ready(is_ready);
	}
    }
    return true;
};

// Find ISO8601 UTC string in the HTML element and convert it.
DcmgrGUI.Util.utcToLocal = function(elemid) {
  var elem = $(elemid);
  elem.html(DcmgrGUI.date.utcToLocal(elem.html()));
};

DcmgrGUI.Event = DcmgrGUI.Class.create({

  initialize: function(){
    this.events = {};
  },
  attach: function(event_name, func){
    if(!this.events[event_name] && typeof func === "function") {
      this.events[event_name] = func;
    }
  },
  detach: function(event_name){
    if(this.events[event_name]) {
      delete this.events[event_name];
    }
  },
  fire: function(event_name){
    if(this.events[event_name]) {
      this.events[event_name]();
    }
  }
});

DcmgrGUI.Notification = DcmgrGUI.Class.create({

  initialize: function() {
    this.topics = {};
    this.evaluation_list = {};
    this.subscription_id = 1;
  },
  create_topic: function(topic_id) {
    if(!this.topics[topic_id]) {
      this.topics[topic_id] = [];
    }
  },
  subscribe: function(topic_id, target, method_name, options) {
    if( this.topics[topic_id] ) {
      this.topics[topic_id].push({'target': target,
                                  'method_name': method_name,
                                  'options': options,
                                  'subscription_id': this.subscription_id});
      var subscription_id = this.subscription_id;
      this.subscription_id += 1;
      return subscription_id;
    }
  },
  add_evaluation: function(subscription_id, logic) {
    this.evaluation_list[subscription_id] = logic;
  },
  evaluate: function(subscription_id) {
    if(jQuery.isFunction(this.evaluation_list[subscription_id])) {
      return this.evaluation_list[subscription_id]();
    } else{
      return true;
    }
  },
  publish: function(topic_id) {
    if(this.topics[topic_id]) {
      var size = this.topics[topic_id].length;
      for (i=0; i < size; i++) {
        var topic = this.topics[topic_id][i];
        var target = topic['target'];
        var method_name = topic['method_name'];
        if(this.evaluate(topic['subscription_id'])) {
          target[method_name](topic['options']);
        }
      }
    }
  }

});

DcmgrGUI.List = DcmgrGUI.Class.create(DcmgrGUI.ContentBase, {
  initialize: function(params){
    DcmgrGUI.ContentBase.prototype.initialize(params);
    this.checked_list = {};
    this.detail_template = {};
    this.maxrow = params.maxrow;
    this.page = params.page;
    this.detail_filter = new DcmgrGUI.Filter(); 
    this.detail_filter.add(function(data){
      
      if(data.item.created_at) {
        data.item.created_at = DcmgrGUI.date.parseISO8601(data.item.created_at);
        data.item.created_at = DcmgrGUI.date.setTimezone(data.item.created_at, dcmgrGUI.getConfig('time_zone'));
        data.item.created_at = DcmgrGUI.date.getI18n(data.item.created_at);
      }

      if(data.item.updated_at) {
        data.item.updated_at = DcmgrGUI.date.parseISO8601(data.item.updated_at);
        data.item.updated_at = DcmgrGUI.date.setTimezone(data.item.updated_at, dcmgrGUI.getConfig('time_zone'));
        data.item.updated_at = DcmgrGUI.date.getI18n(data.item.updated_at);
      }

      if(data.item.last_login_at) {
        data.item.last_login_at = DcmgrGUI.date.parseISO8601(data.item.last_login_at);
        data.item.last_login_at = DcmgrGUI.date.setTimezone(data.item.last_login_at, dcmgrGUI.getConfig('time_zone'));
        data.item.last_login_at = DcmgrGUI.date.getI18n(data.item.last_login_at);
      }

      return data;
    });

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
          });
        }
      });
    });
    
    this.element.bind('dcmgrGUI.updateList',function(event,params){
      self.update(params.request,true);
    });
    dcmgrGUI.notification.create_topic('checked_box');
    dcmgrGUI.notification.create_topic('unchecked_box');
    dcmgrGUI.notification.create_topic('checked_radio');
  },
  setDetailTemplate:function(template){
    this.detail_template = template;
  },
  getCheckedInstanceIds:function(){
    var ids = [];
    for(var id in this.checked_list){
      ids.push(id);
    }
    return { 
      'ids':ids
    };
  },
  checkRadioButton:function(id){
    $('#'+id).attr("checked", true);
  },
  setData:function(json){
    var rows = [];
    if(!json){
      rows = this.getEmptyData();
    }else{
      $.each(json,function(key,value){
        rows.push(value.result);
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
    this.checked_list = {};
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
  currentMultiChecked:function(){
    var checked_list = this.element.find("[type='checkbox']:checked");
    var ids = [];
    
    $.each(checked_list, function(key, item){
     ids.push($(item).val());
    })
    
    return {
      'ids':ids
    };
  },
  singleCheckList:function(params){
    var self = this;
    this.element.find("[type='radio']").each(function(key,value){
      $(this).click(function(){
        var check_id = $(this).val();
        
        if($(this).is(':checked')){
          
          dcmgrGUI.notification.publish('checked_radio');
          
          var c_detail = new DcmgrGUI.Detail({
            template_id:params.template_id
          });
           
          c_detail.element.bind('dcmgrGUI.contentChange',function(event,params){
            var data = { item:params.data };
            //initialize
            if(!params.data){
              data.item = self.getEmptyData();
            }

            if(data.item){
              self.detail_filter.execute(data);
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
    var checkboxies = this.element.find("[type='checkbox']");
    checkboxies.each(function(key,value){
      
      $(this).click(function(){
        var check_id = $(this).val();
        
        if($(this).is(':checked')){
          dcmgrGUI.notification.publish('checked_box');
          
          //step1:onclick checkbox and generate detail object
          self.checked_list[check_id] = {
            //+1 is to remove table header
            element:$(self.element.find('tr')[key+1]),
            c_detail:new DcmgrGUI.Detail({
              //id is to search element key
              id:check_id,
              template_id:params.template_id
            })
          };
          
          //step2:bind event dcmgrGUI.contentChange
          var detail_element = self.checked_list[check_id].c_detail.element;
          detail_element.bind('dcmgrGUI.contentChange',function(event,params){
            if(self.checked_list[check_id]){
            
              //step4:marge data in template
              var data = { item:params.data };
              
              //initialize
              if(!params.data){
                data.item = self.checked_list[check_id].c_detail.getEmptyData();
              }
              
              self.checked_list[check_id].c_detail.filter.execute(data);
              
              if(data.item){
                self.detail_filter.execute(data);
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
          dcmgrGUI.notification.publish('unchecked_box');
          //remove detail
          if(self.checked_list[check_id]){
            $($('#detail').find('#'+check_id)).remove();
            delete self.checked_list[check_id];
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
    this.target = '.refresh';
    this.element = $(this.target);
    var self = this;
    self.element.live('click',function(){
      self.element.trigger('dcmgrGUI.refresh');
    });
  }
});

DcmgrGUI.ItemSelector = DcmgrGUI.Class.create({
  
  initialize: function(params) {
    this.element = $(params.target);
    this.left_select_id = params.left_select_id;
    this.right_select_id = params.right_select_id;
    this.data = params.data;
    
    this.leftSelectionsArray = this.emptyArray(this.data.length);
    var dataSize = this.data.length;
    for(var i = 0;i < dataSize ;i++) {
      if (!this.data[i]['selected']) {
        var html = '<option id="'+i+'" value="'+ this.data[i]['value'] +'">'+ this.data[i]['name'] +'</option>';
        this.leftSelectionsArray[i] = $(html);
      }
    }
    this.rightSelectionsArray = this.emptyArray(this.data.length);
    for(var i = 0;i < dataSize ;i++) {
      if (this.data[i]['selected']) {
        var html = '<option id="'+i+'" value="'+ this.data[i]['value'] +'">'+ this.data[i]['name'] +'</option>';
        this.rightSelectionsArray[i] = $(html);
      }
    }
    
    this.refreshOptions(this.right_select_id,this.rightSelectionsArray);
    this.refreshOptions(this.left_select_id,this.leftSelectionsArray);
  },
  refreshOptions: function(select_id,selectionsArray){
    var selectionsSize = selectionsArray.length;
    $(select_id).html('');
    for(var i = 0;i < selectionsSize  ;i++) {
      if(selectionsArray[i] !== null ){
        this.element.find(select_id).append(selectionsArray[i]);
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
    this.element.find(this.left_select_id).find('option:selected').each(function(){
      var index = $(this).attr('id');
      self.leftSelectionsArray[index] = null;
      self.rightSelectionsArray[index] = this;
      $(this).remove();
    });
    
    this.refreshOptions(this.right_select_id,this.rightSelectionsArray);
  },
  rightToLeft: function() {
    var self = this;
    this.element.find(this.right_select_id).find('option:selected').each(function(){
      var index = $(this).attr('id');
      self.leftSelectionsArray[index] = this;
      self.rightSelectionsArray[index] = null;
      $(this).remove();
    });
    
    this.refreshOptions(this.left_select_id,this.leftSelectionsArray);
  },
  getRightSelectionCount: function(){
    var count = 0;
    $.each(this.rightSelectionsArray,function(key, value){
     if(value != null) {
      count++;
     } 
    });
    return count;
  }

});

DcmgrGUI.ToolTip　= DcmgrGUI.Class.create({
  initialize: function(params) {
    this.target = params.target;
    this.element = $(params.element);
  },
  create: function(params){
    this.content = this.element.find(this.target)
                       .cluetip(params);
  },
  close: function(){
    this.content.trigger('hideCluetip');
  }
});

DcmgrGUI.Logger = DcmgrGUI.Class.create({
  initialize: function() {
    this.stack = [];
  },
  push: function(type, item) {
    this.stack.push({
      'type': type,
      'item': item
    });
  },
  getLog: function(limit, type) {
    var size = this.stack.length;
    var results = [];
    var count = 0;
    var limit = limit || this.stack.length;
    var type = 'ajaxError';
    for(var i=0; i< size; i++) {
      if(this.stack[i].type == type) {
        if(count < limit) {
          results.push(this.stack[i]);
          count +=1;
        } else {
          break;
        }
      }
    }
    return results;
  }
});


DcmgrGUI.VifMonitorSelector = DcmgrGUI.Class.create({
  initialize: function(elem) {
    this.index_counter = 0;
    this.monitor_list = [];
    this.render_target = elem;
  },

  monitors: function(){
    return this.monitor_list;
  },

  _newIndex: function() {
    return (this.index_counter++);
  },
  
  addItem: function(protocol){
    var self = this;
    var idx = this._newIndex();
    if(DcmgrGUI.VifMonitorSelector.MONITOR_ITEMS()[protocol] === undefined) {
      throw "Unknown protocol parameter is passed: " + protocol;
    }

    // place holder variable for event handlers.
    var item_props = {"protocol":protocol,
                      'idx': idx,
                     };
    this.monitor_list.push(item_props);

    var tr_tag = $('#monitor_selector_tmpl').tmpl({idx: idx,
                                                   itemlist: DcmgrGUI.VifMonitorSelector.MONITOR_ITEMS(),
                                                  });
    tr_tag.appendTo(this.render_target);
    tr_tag.find('.del_monitor_item').first().bind('click', function(e){
      // remove the clicked item from the list.
      self.monitor_list.splice((idx - 1), 1);
      $('#monitor_item_' + idx).first().remove();
    });
    
    tr_tag.find('.select_monitor_proto').first().bind('change', function(e){
      item_props['protocol']=$(e.currentTarget).val();

      var replace_tgt = $(e.currentTarget).parent().parent().find(".detail_input");
      // fill input UI elements for the protocol selected by user.
      var row_item = DcmgrGUI.VifMonitorSelector.MONITOR_ITEMS()[e.target.value];
      if(row_item === undefined){
        throw "Unknown monitor protocol: " + e.target.value;
      }
      // Clear current child elements.
      replace_tgt.html('');
      row_item.ui(replace_tgt, e.target.id);
    }).val(protocol).trigger('change');

    item_props['row_elem'] = tr_tag;
  },

  queryParams: function(){
    var res="";

    for (var i=0; i < this.monitor_list.length; i++) {
      var itm = this.monitor_list[i]
      res += "&eth0_monitors["+i+"][protocol]=" + itm['protocol'];
      res += "&eth0_monitors["+i+"][enabled]=" + $(itm['row_elem']).find('.enabled').is(':checked');
      res += DcmgrGUI.VifMonitorSelector.MONITOR_ITEMS()[itm['protocol']].buildQuery(itm['row_elem'], i);
    }

    return res;
  },
});

DcmgrGUI.VifMonitorSelector.MONITOR_ITEMS = function(){
  return {
    'icmp': {
      title: "PING",
      ui: function (elem){
      },
      buildQuery: function(row_elem, idx){
        return "";
      },
    },
    'http': {
      title: "HTTP",
      ui: function (elem){
        elem.append('Port: <input type="text" class="_tcp_port" width="4" value="80"></input>');
        elem.append('<br>Path: <input type="text" class="_check_path" width="40" value="/"></input>');
      },
      buildQuery: function(row_elem, idx){
        return "&eth0_monitors["+idx+"][params][port]="+$(row_elem).find('._tcp_port').val() +
          "&eth0_monitors["+idx+"][params][check_path]="+$(row_elem).find('._check_path').val();
      },
    },
    'https': {
      title: "HTTPS",
      ui: function (elem, idx){
        elem.append('Port: <input type="text" class="_tcp_port" width="4" value="443"></input>');
        elem.append('<br>Path: <input type="text" class="_check_path" width="40" value="/"></input>');
      },
      buildQuery: function(row_elem, idx){
        return "&eth0_monitors["+idx+"][params][port]="+$(row_elem).find('._tcp_port').val() +
          "&eth0_monitors["+idx+"][params][check_path]="+$(row_elem).find('._check_path').val();
      },
    },
    'ftp': {
      title: "FTP",
      ui: function (elem, idx){
        elem.append('Port: <input type="text" class="_tcp_port" width="4" value="21"></input>');
      },
      buildQuery: function(row_elem, idx){
        return "&eth0_monitors["+idx+"][params][port]="+$(row_elem).find('._tcp_port').val();
      },
    },
    'ssh': {
      title: "SSH",
      ui: function (elem, idx){
        elem.append('Port: <input type="text" class="_tcp_port" width="4" value="22"></input>');
      },
      buildQuery: function(row_elem, idx){
        return "&eth0_monitors["+idx+"][params][port]="+$(row_elem).find('._tcp_port').val();
      },
    },
    'smtp': {
      title: "SMTP",
      ui: function (elem, idx){
        elem.append('Port: <input type="text" class="_tcp_port" width="4" value="25"></input>');
      },
      buildQuery: function(row_elem, idx){
        return "&eth0_monitors["+idx+"][params][port]="+$(row_elem).find('._tcp_port').val();
      },
    },
    'pop3': {
      title: "POP3",
      ui: function (elem, idx){
        elem.append('Port: <input type="text" class="_tcp_port" width="4" value="110"></input>');
      },
      buildQuery: function(row_elem, idx){
        return "&eth0_monitors["+idx+"][params][port]="+$(row_elem).find('._tcp_port').val();
      },
    },
    'imap': {
      title: "IMAP",
      ui: function (elem, idx){
        elem.append('Port: <input type="text" class="_tcp_port" width="4" value="143"></input>');
      },
      buildQuery: function(row_elem, idx){
        return "&eth0_monitors["+idx+"][params][port]="+$(row_elem).find('._tcp_port').val();
      },
    },
    'submission': {
      title: "Submission",
      ui: function (elem, idx){
        elem.append('Port: <input type="text" class="_tcp_port" width="4" value="587"></input>');
      },
      buildQuery: function(row_elem, idx){
        return "&eth0_monitors["+idx+"][params][port]="+$(row_elem).find('._tcp_port').val();
      },
    },
    'dns': {
      title: "DNS",
      ui: function (elem, idx){
        elem.append('Host Query: <input type="text" class="_query_record" value="localhost"></input>');
        elem.append('<input type="hidden" class="_udp_port" value="53"></input>');
      },
      buildQuery: function(row_elem, idx){
        return "&eth0_monitors["+idx+"][params][port]=53&eth0_monitors["+idx+"][params][query_record]"+$(row_elem).find('._query_record').val();
      },
    },
    'mysql': {
      title: "MySQL",
      ui: function (elem, idx){
        elem.append('Port: <input type="text" class="_tcp_port" width="4" value="3306"></input>');
      },
      buildQuery: function(row_elem, idx){
        return "&eth0_monitors["+idx+"][params][port]="+$(row_elem).find('._tcp_port').val();
      },
    },
    'postgresql': {
      title: "PostgreSQL",
      ui: function (elem, idx){
        elem.append('Port: <input type="text" class="_tcp_port" width="4" value="5432"></input>');
      },
      buildQuery: function(row_elem, idx){
        return "&eth0_monitors["+idx+"][params][port]="+$(row_elem).find('._tcp_port').val();
      },
    }
  };
};

DcmgrGUI.prototype = {
  initialize:function(){
    $.deferred.define();
    this.config = {
      error_popup: true,
      error_popup_once: true
    };

    this.logger = new DcmgrGUI.Logger();
  },
  getConfig: function(key){
    return this.config[key];
  },
  setConfig: function(key, value) {
    this.config[key] = value;
  }
}
