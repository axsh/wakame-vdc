/*-
 * Copyright (c) 2010 axsh co., LTD.
 * All rights reserved.
 *
 * Author: Takahisa Kamiya
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 */

// Global Resources
Ext.apply(WakameGUI, {
  ResourceEditor:null,
  ResourceMap:null,
  ResourceTree:null,
  ResourceProperty:null,
  MapProperty:null,
  RackProperty:null,
  ServerProperty:null,
  ResourceServer:null,
  ResourceRack:null,
  resourceMapPanel:null,
  resourceTreePanel:null,
  resourcePropertyPanel:null,
  dataRacks:null,
  newRackid:0,
  newServerid:0
});

WakameGUI.ResourceServer = function(id,name){
  this.id = id;
  this.name = name;
  this.append = false;				// 新規追加
  this.edit = false;				// 編集されたか？（座標が変わった場合も含む）
}

WakameGUI.ResourceRack = function(id,name,x,y){
  this.id = id;
  this.name = name;
  this.x = x;
  this.y = y;
  this.append = false;				// 新規追加
  this.edit = false;				// 編集されたか？（座標が変わった場合も含む）
  this.sel  = false;				// 選択されているか？
  this.draw_id = null;				// divのID
  this.servers = new Array();
  this.add = function(obj){
    this.servers.push(obj);
  }
}

WakameGUI.ResourceEditor = function(){
  WakameGUI.resourceMapPanel  = new WakameGUI.ResourceMap();
  WakameGUI.resourceTreePanel = new WakameGUI.ResourceTree();
  WakameGUI.resourcePropertyPanel = new WakameGUI.ResourceProperty();

  var editPanel = new Ext.Panel({
    region: 'east',
    width: 150,
    defaults     : { flex  : 1 }, //auto stretch
    layoutConfig : { align : 'stretch' },
    split: true,
	layout: 'vbox',
    items : [WakameGUI.resourceTreePanel,WakameGUI.resourcePropertyPanel]
  });

  function reqeustSuccess(response)
  {
    if (response.responseText !== undefined) { 
      var data = Ext.decode(response.responseText);
      WakameGUI.dataRacks = new Array();
	  var max = data.racks['racks'].length;
      for(var i=0;i<max;i++){
        var id = data.racks['racks'][i].id;
        var name = data.racks['racks'][i].name;
        var x = data.racks['racks'][i].x;
        var y = data.racks['racks'][i].y;
        var rackData = new WakameGUI.ResourceRack(id,name,x,y);
        var smax = data.racks['racks'][i]['servers'].length;
        for(var j=0;j<smax;j++){
          var svrData = new WakameGUI.ResourceServer(data.racks['racks'][i]['servers'][j].id,data.racks['racks'][i]['servers'][j].name)
          rackData.add(svrData);
        }
        WakameGUI.dataRacks.push(rackData);
      }
      WakameGUI.resourceMapPanel.drawRack();
      WakameGUI.resourceTreePanel.drawTree();
    }
  }

  function  requestfailure()
  {
    alert('Request failure.');
  }

  function loadRackList(id){
    Ext.Ajax.request({
	  url: '/rack-list',
	  method: "GET",
      params : 'id=' + id,
      success: reqeustSuccess,
      failure: requestfailure
	});
  }

  var store = new Ext.data.Store({
    proxy: new Ext.data.HttpProxy({
      url: '/map-list',
      method:'GET'
    }),
    listeners: {
      'load': function( temp , records, ope ){
        if(records.length > 0){
          combo.setValue(records[0].id);
          loadRackList(records[0].id);
          WakameGUI.resourceMapPanel.setMapInfo(records[0].data.url,records[0].data.grid);
        }
      }
    },
    reader: new Ext.data.JsonReader({
      totalProperty: "count",
      root:'maps',
      fields:[
        { name:'id'    ,type:'string'},
        { name:'name'  ,type:'string'},
        { name:'url'   ,type:'string'},
        { name:'grid'  ,type:'int'},
        { name:'memo'  ,type:'string'}
      ]
    })
  });
  store.load();

  var combo = new Ext.form.ComboBox({
    typeAhead: true,
    lazyRender:true,
    editable: false,
    width: 100, 
    triggerAction: 'all',
    forceSelection:true,
    mode: 'local',
    store: store,
    valueField: 'id',
    displayField: 'name',
    listeners: {
      'select': function(cb,rec,index){
//      console.debug(rec);
//      console.debug(index);
        loadRackList(rec.id);
        WakameGUI.resourceMapPanel.setMapInfo(rec.data.url,rec.data.grid);
      }
    }
  });

  WakameGUI.ResourceEditor.superclass.constructor.call(this, {
    split: true,
    header: false,
    border: false,
    layout: 'border',
    items: [WakameGUI.resourceMapPanel,editPanel],
    tbar : [
      {
        iconCls: 'icon-add',
        text: 'Add',
        handler:function(){
          WakameGUI.resourceMapPanel.addRack();
        }
      },'-',
      combo
    ]
  });
}
Ext.extend(WakameGUI.ResourceEditor, Ext.Panel);

WakameGUI.ResourceTree = function(){
  var root = new Ext.tree.TreeNode({
    draggable:false,
    id:"root",
    text:"",
    expanded:true,
    leaf:false
  });

  function createNode( id, text, isLeaf, isDrag ){
    return new Ext.tree.TreeNode({
      draggable:isDrag,
      id:id,
      text:text,
      expanded:true,
      leaf:isLeaf
    });
  }

  function drawTree(){
    var max=root.childNodes.length;
    for(var i=0;i<max;i++){
      root.childNodes[0].remove();
    }
    for(var i=0;i<WakameGUI.dataRacks.length;i++){
      var id = WakameGUI.dataRacks[i].id;
      var nm = WakameGUI.dataRacks[i].name;
      var rack = createNode( id, nm, false, false );
      var smax = WakameGUI.dataRacks[i].servers.length;
      for(var j=0;j<smax;j++){
        var sid = WakameGUI.dataRacks[i].servers[j].id;
        var snm = WakameGUI.dataRacks[i].servers[j].name
        rack.appendChild(createNode( nm+":"+sid, snm, true, false ));
      }
      root.appendChild(rack);
    }
  }
  this.drawTree = function(){
    drawTree();
  }

  function addServer(rackid){
    for(var i=0;i<WakameGUI.dataRacks.length;i++){
      if(WakameGUI.dataRacks[i].id == rackid){
        var svrData = new WakameGUI.ResourceServer("S-" + WakameGUI.newServerid,"Untitled");
        svrData.append = true;
        WakameGUI.dataRacks[i].add(svrData);
        WakameGUI.newServerid++;
        break;
      }
    }
    drawTree();
  }
  this.addServer = function(id){
    addServer(id);
  }

  WakameGUI.ResourceTree.superclass.constructor.call(this,{
    split: true,
    autoScroll: true,
    title: 'Server',
    border: false,
    useArrows:true,
    width: 160,
    rootVisible: false,
    tbar : [
      {
        iconCls: 'icon-add',
        handler:function(){
          var selNode = WakameGUI.resourceTreePanel.getSelectionModel().selNode;
          if(selNode == null){
            return;
          }
          var ids = selNode.getPath().split("/");
          if(ids.length>2){
            addServer(ids[2]);
          }
        }
      },
      { iconCls: 'icon-delete',
        handler:function(){
        }
      }
    ],
    root:root,
    listeners: {
      'click': function(node){
//        console.debug(node.getPath());
        var ids = node.getPath().split("/");
        if(ids.length>2){
          if(ids.length==3){
            WakameGUI.resourcePropertyPanel.selectProperty(1);
          }else{
            WakameGUI.resourcePropertyPanel.selectProperty(2);
          }
          for(var i=0;i<WakameGUI.dataRacks.length;i++){
            if(WakameGUI.dataRacks[i].id == ids[2]){	// RACK-ID
              WakameGUI.dataRacks[i].sel = true;
            }
            else{
              WakameGUI.dataRacks[i].sel = false;
            }
          }
          WakameGUI.resourceMapPanel.drawRack();
        }
      }
    }
  });
}
Ext.extend(WakameGUI.ResourceTree, Ext.tree.TreePanel);

WakameGUI.ResourceMap = function(){
  var grid_x = 20;
  var grid_y = 20;
  var map_url = Ext.BLANK_IMAGE_URL;
  var render_end = false;
  var rack_width = 20;
  var rack_high  = 15;
  var boxDraw=false;
  var mousex1=0;
  var mousey1=0;
  var mousex2=0;
  var mousey2=0;
  var dataMap = new Array();
  var draggingRack=false;

  function clearRackSelect(target){
	for(var i=0;i<WakameGUI.dataRacks.length;i++){
      if(WakameGUI.dataRacks[i].id != dataMap[Ext.get(target).id]){
        if(WakameGUI.dataRacks[i].sel){
          WakameGUI.dataRacks[i].sel = false;
          var myEl = Ext.get(WakameGUI.dataRacks[i].draw_id);
          myEl.applyStyles({ 'background-color':'green' });
        }
      }
    }
  }

  function dragRack(target){
    var top = Ext.get('rackSurface');
    var x = Ext.get(target).getX()-top.getX();
    var y = Ext.get(target).getY()-top.getY();
    var dist_x = Math.floor(x / grid_x)*grid_x;
    var dist_y = Math.floor(y / grid_y)*grid_y;
    if((x % grid_x) > (grid_x/2)){
      dist_x += grid_x;
    }
    if((y % grid_y) > (grid_y/2)){
      dist_y += grid_y;
    }
    Ext.get(target).setX(top.getX()+dist_x);
    Ext.get(target).setY(top.getY()+dist_y);
    var move_x = 0;
    var move_y = 0;
	for(var i=0;i<WakameGUI.dataRacks.length;i++){
      if(WakameGUI.dataRacks[i].id == dataMap[Ext.get(target).id]){
        if(!WakameGUI.dataRacks[i].sel){
          WakameGUI.dataRacks[i].sel = true;
          var myEl = Ext.get(WakameGUI.dataRacks[i].draw_id);
          myEl.applyStyles({ 'background-color':'red' });
          // ドラッグ対象が選択されていなかった場合
　　　　　// 他の選択されていたラックを選択解除する
          // ドラッグの際に単独で選択されたとみなす
          clearRackSelect(target);
        }
        move_x = WakameGUI.dataRacks[i].x-dist_x;
        move_y = WakameGUI.dataRacks[i].y-dist_y;
        WakameGUI.dataRacks[i].x = dist_x;
        WakameGUI.dataRacks[i].y = dist_y;
        break;
      }
	}
	for(var i=0;i<WakameGUI.dataRacks.length;i++){
      if(WakameGUI.dataRacks[i].id != dataMap[Ext.get(target).id]){
        if(WakameGUI.dataRacks[i].sel){
          dist_x = WakameGUI.dataRacks[i].x-move_x;
          dist_y = WakameGUI.dataRacks[i].y-move_y;
          WakameGUI.dataRacks[i].x = dist_x;
          WakameGUI.dataRacks[i].y = dist_y;
          Ext.get(WakameGUI.dataRacks[i].draw_id).setX(top.getX()+dist_x);
          Ext.get(WakameGUI.dataRacks[i].draw_id).setY(top.getY()+dist_y);
        }
      }
    }
  }

  var taskEndDrag = new Ext.util.DelayedTask(function(){
    draggingRack=false;
  });

  function init(){
    Ext.override(Ext.dd.DD, {
      startDrag :  function(x, y){
        draggingRack=true;
      },
      onDrag : function(e){
        dragRack(this.getEl());
      },
      endDrag: function(e) {
        dragRack(this.getEl());
        taskEndDrag.delay(50);
      }
    });
    var top = Ext.get('canvas');
    top.addListener("mousedown",mousedownHandler);
    top.addListener("mouseup",mouseupHandler);
    top.addListener("mousemove",mousemoveHandler);
    top.addListener("mouseout",mouseoutHandler);
  }

  function getCanvas()
  {
    var canvas = Ext.getDom("canvas");
    if(canvas.getContext){
      var ctx = canvas.getContext("2d");
      ctx.lineWidth = 1;
      return ctx;
    }
    return null;
  }

  function setScreenSize()
  {
    var canvas = Ext.getDom("canvas");
    var map = Ext.getDom('map');
    canvas.height = map.height;
    canvas.width = map.width;
  }

  function clearSelCanvas(ctx){
    var canvas = Ext.getDom("canvas");
    ctx.clearRect(0,0,canvas.width,canvas.height);
  }

  function gridLine(ctx) {
    var map = Ext.getDom('map');
    ctx.globalAlpha = 0.8;
    ctx.lineWidth = 1;
    ctx.strokeStyle = 'rgb(204,204,153)';
    var x = grid_x;
    for(i=0;i<(map.width/grid_x);i++){
      ctx.beginPath();
      ctx.moveTo(x+0.1,0);
      ctx.lineTo(x+0.1,map.height+0.1);
      ctx.stroke();
      x += grid_x;
    }
    var y = grid_y;
    for(i=0;i<(map.height/grid_y);i++){
      ctx.beginPath();
      ctx.moveTo(0,y+0.1);
      ctx.lineTo(map.width+0.1,y+0.1);
      ctx.stroke();
      y += grid_y;
    }
  }

  function mousedownHandler(e, target) {
    boxDraw=true;
    var top = Ext.get('rackSurface');
    mousex1=e.browserEvent.clientX-top.getX();
    mousey1=e.browserEvent.clientY-top.getY();
  }

  function mouseSelectCancel() { 
    var ctx = getCanvas();
    if(ctx != null){
      clearSelCanvas(ctx);
      gridLine(ctx);
    }
    boxDraw=false;
  }

  function mouseupHandler(e, target) { 
    var top = Ext.get('rackSurface');
    mousex2=e.browserEvent.clientX-top.getX();
    mousey2=e.browserEvent.clientY-top.getY();
    if(mousex1>mousex2){
      var temp = mousex2;
      mousex2 = mousex1;
      mousex1 = temp;
    }
    if(mousey1>mousey2){
      var temp = mousey2;
      mousey2 = mousey1;
      mousey1 = temp;
    }
    for(var i=0;i<WakameGUI.dataRacks.length;i++){
      var x = WakameGUI.dataRacks[i].x;
      var y = WakameGUI.dataRacks[i].y;
      if(mousex1 <= x && mousex2 >=x && mousey1 <= y && mousey2 >= y){
        WakameGUI.dataRacks[i].sel = true;
      }
      else{
        WakameGUI.dataRacks[i].sel = false;
      }
	}
    mouseSelectCancel();
    drawRack();
    // rack treeの選択を解除
    WakameGUI.resourceTreePanel.selectPath("/root");
    // todo: disp map info propety
    WakameGUI.resourcePropertyPanel.selectProperty(0);
  }

  function mousemoveHandler(e, target) { 
    if(boxDraw){
      var ctx = getCanvas();
      if(ctx != null){
        clearSelCanvas(ctx);
        gridLine(ctx);
        var top = Ext.get('rackSurface');
        mousex2=e.browserEvent.clientX-top.getX();
        mousey2=e.browserEvent.clientY-top.getY();
        ctx.strokeStyle = 'rgb(255,0,0)';
        ctx.rect(mousex1,mousey1,mousex2-mousex1,mousey2-mousey1);
        ctx.stroke();
      }
    }
  }

  function  mouseoutHandler(e, target){
    mouseSelectCancel();
  }

  function  selectRack(e,target) {
    if(draggingRack){
      return;
    }
//  console.debug(target.id);
//  console.debug(dataMap[target.id]);
    for(var i=0;i<WakameGUI.dataRacks.length;i++){
      if(WakameGUI.dataRacks[i].id == dataMap[target.id]){
        WakameGUI.dataRacks[i].sel = true;
        if(e.browserEvent.ctrlKey){
          break;
        }
	  }
      else{
        if(!e.browserEvent.ctrlKey){
          WakameGUI.dataRacks[i].sel = false;
        }
      }
    }
    drawRack();
    WakameGUI.resourceTreePanel.selectPath("/root/"+dataMap[target.id]);
    WakameGUI.resourcePropertyPanel.selectProperty(1);
  }

  this.setMapInfo = function(url,grid){
    map_url = url;
    grid_x  = grid;
    grid_y  = grid;
    if(render_end){
      changeMap();
    }
  }

  function drawRack() {
    if(render_end){
	  for(var i=0;i<WakameGUI.dataRacks.length;i++){
        if(WakameGUI.dataRacks[i].draw_id == null){
          var x = WakameGUI.dataRacks[i].x;
          var y = WakameGUI.dataRacks[i].y;
          var id = WakameGUI.dataRacks[i].id;
          var sel = WakameGUI.dataRacks[i].sel;
	      var rtn = deployRack(x,y,sel);
	      dataMap[rtn] = id;
          WakameGUI.dataRacks[i].draw_id = rtn;
        }
        else{
          var tid = WakameGUI.dataRacks[i].draw_id;
          var sel = WakameGUI.dataRacks[i].sel;
          var myEl = Ext.get(tid);
          if(sel){
            myEl.applyStyles({ 'background-color':'red' });
          }
          else{
            myEl.applyStyles({ 'background-color':'green' });
          }
        }
	  }
	}
  }
  this.drawRack = function(){
    drawRack();
  }

  function changeMap(){
    var map = Ext.getDom('map');
    map.src = map_url;
    map.onload = function() {
      setScreenSize();
      var ctx = getCanvas();
      if(ctx != null){
        gridLine(ctx);
      }
      map.onload = "";
    }
  }

  var taskDrawMap = new Ext.util.DelayedTask(function(){
    changeMap();
  });
  var taskDrawRack = new Ext.util.DelayedTask(function(){
    drawRack();
    WakameGUI.resourceTreePanel.drawTree();
  });

  var selectedRack = null;

  var myMenu = new Ext.menu.Menu({
    style: { overflow: 'visible' },
    items: [
      {text:'add server',
        handler: function(node,e){
// todo: input infomation window
          WakameGUI.resourceTreePanel.addServer(dataMap[selectedRack]);
          selectedRack = null;
        }
      },
      {text:'delete rack',
        handler: function(node,e){
//          console.debug(selectedRack);
          selectedRack = null;
        }
      }
    ]
  });

  function deployRack(x,y,sel){
    var myEl = new Ext.Element(document.createElement('div'));
    myEl.setWidth(rack_width-2);
    myEl.setHeight(rack_high-2);
    myEl.setStyle({ 'position':'absolute' });
    if(sel){
      myEl.setStyle({ 'background-color':'red' });
    }
    else{
      myEl.setStyle({ 'background-color':'green' });
    }
    myEl.setStyle({ 'border-style':'solid' });
    myEl.setStyle({ 'border-color':'black' });
    myEl.setStyle({ 'border-width':'2px' });
    myEl.setLocation(x,y);
    myEl.on('contextmenu', function(e,w,q){
      selectedRack = this.id;
      myMenu.showAt(e.getXY());
    }, null, {stopEvent:true});
    myEl.addListener("click",selectRack);
    Ext.get('rackSurface').appendChild(myEl.dom);
    new Ext.dd.DD(myEl, "group1");
    return myEl.id;
  }

  this.addRack = function(){
	// serverでラックのインスタンスを作成
    var x = 20;
    var y = 20;
    // 座標の正規化??
    var rackData = new WakameGUI.ResourceRack("R-" + WakameGUI.newRackid,"Untitled",x,y);
    WakameGUI.newRackid++;		// 仮IDを付ける（重複しないもの）
    // 選択状態の変更
    // 他に選択されているラックをキャンセル
	for(var i=0;i<WakameGUI.dataRacks.length;i++){
      WakameGUI.dataRacks[i].sel = false;
	}
    rackData.sel = true;
    WakameGUI.dataRacks.push(rackData);
    drawRack();
    WakameGUI.resourceTreePanel.drawTree();
  }

  WakameGUI.ResourceMap.superclass.constructor.call(this, {
    region: 'center',
    autoScroll: true,
    split: true,
    layout: 'fit',
    listeners:{
      'afterrender': function(){
         init();
         if(map_url != Ext.BLANK_IMAGE_URL){
           taskDrawMap.delay(50); 
         }
         if(WakameGUI.dataRacks != null){
           taskDrawRack.delay(100);
         }
         render_end = true;
      }
    },
    html: '<div style="position:absolute"><img id="map" src="'+Ext.BLANK_IMAGE_URL+'"></div><canvas id="canvas" style="position:absolute"></canvas><div id="rackSurface" style="position:absolute"></div>'
  });
}
Ext.extend(WakameGUI.ResourceMap, Ext.Panel, {}); 

WakameGUI.ResourceProperty = function(){
  var mapProperty    = new WakameGUI.MapProperty();
  var rackProperty   = new WakameGUI.RackProperty();
  var serverProperty = new WakameGUI.ServerProperty();

  this.selectProperty = function(no){
    this.layout.setActiveItem(no);
    switch(no){ 
      case 0:
        this.setTitle("Map Property");
        break;
      case 1:
        this.setTitle("Rack Property");
        break;
      case 2:
        this.setTitle("Server Property");
        break;
    }
  }

  WakameGUI.ResourceProperty.superclass.constructor.call(this, {
    title: "Map Property",
    autoScroll: true,
    split: true,
    width: 150,
    bodyStyle:'padding:5px',
	layout:'card',
	activeItem: 0,
	items: [mapProperty,rackProperty,serverProperty]
  });
}
Ext.extend(WakameGUI.ResourceProperty, Ext.Panel);

WakameGUI.MapProperty = function(){
  WakameGUI.MapProperty.superclass.constructor.call(this, {
    autoScroll: true,
    labelWidth: 35,
    frame : true,
    baseCls: 'x-plain',
    items: [
      {
      fieldLabel: 'Name',
      xtype: 'textfield',
      name: 'user_name',
      anchor: '100%'
      }
      ,{
      fieldLabel: 'Memo',
      xtype: 'textarea',
      name: 'memo',
      anchor: '100%'
      }
    ]
  });
}
Ext.extend(WakameGUI.MapProperty, Ext.form.FormPanel);

WakameGUI.RackProperty = function(){
  WakameGUI.RackProperty.superclass.constructor.call(this, {
    autoScroll: true,
    labelWidth: 35,
    frame : true,
    baseCls: 'x-plain',
    items: [
      {
      fieldLabel: 'Name',
      xtype: 'textfield',
      name: 'user_name',
      anchor: '100%'
      }
      ,{
      fieldLabel: 'Memo',
      xtype: 'textarea',
      name: 'memo',
      anchor: '100%'
      }
    ]
  });
}
Ext.extend(WakameGUI.RackProperty, Ext.form.FormPanel);

WakameGUI.ServerProperty = function(){
  WakameGUI.ServerProperty.superclass.constructor.call(this, {
    autoScroll: true,
    labelWidth: 35,
    frame : true,
    baseCls: 'x-plain',
    items: [
      {
      fieldLabel: 'Name',
      xtype: 'textfield',
      name: 'user_name',
      anchor: '100%'
      }
      ,{
      fieldLabel: 'Memo',
      xtype: 'textarea',
      name: 'memo',
      anchor: '100%'
      }
    ]
  });
}
Ext.extend(WakameGUI.ServerProperty, Ext.form.FormPanel);
