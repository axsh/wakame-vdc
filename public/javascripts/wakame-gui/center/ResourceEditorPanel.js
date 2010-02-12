
var dataJson = null;
var resourceTreePanel = null;
var mapPanel = null;

ResourceEditorPanel = function(){
  mapPanel = new MapPanel();
  resourceTreePanel = new ResourceTreePanel();
  var palletPanel = new PalletPanel();
  var resourcePropertyPanel = new ResourcePropertyPanel();
  var editPanel = new Ext.Panel({
    region: 'east',
    width: 150,
    defaults     : { flex : 1 }, //auto stretch
    layoutConfig : { align : 'stretch' },
    split: true,
	layout: 'vbox',
    items : [resourceTreePanel,resourcePropertyPanel]
  });

  function reqeustSuccess(response)
  {
    if (response.responseText !== undefined) { 
      dataJson = Ext.decode(response.responseText);
      mapPanel.drawRack();
      resourceTreePanel.drawTree();
    }
  }

  function  reqeustfailure()
  {
    alert('Request failure.');
  }

  function loadRackList(id){
    Ext.Ajax.request({
	  url: '/rack-list',
	  method: "GET",
      params : 'id=' + id,
      success: reqeustSuccess,
      failure: reqeustfailure
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
          mapPanel.setMapInfo(records[0].data.url,records[0].data.grid);
        }
      }
    },
    reader: new Ext.data.JsonReader({
      totalProperty: "count",
      root:'rows',
      fields:[
        { name:'id'    ,type:'string'},
        { name:'nm'    ,type:'string'},
        { name:'url'   ,type:'string'},
        { name:'grid'  ,type:'int'}
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
    displayField: 'nm',
    listeners: {
      'select': function(cb,rec,index){
      console.debug(rec);
//      console.debug(index);
        loadRackList(rec.id);
        mapPanel.setMapInfo(rec.data.url,rec.data.grid);
      }
    }
  });

  ResourceEditorPanel.superclass.constructor.call(this, {
    split: true,
    header: false,
    border: false,
    layout: 'border',
    items: [palletPanel,mapPanel,editPanel],
    tbar: [combo]
  });
}
Ext.extend(ResourceEditorPanel, Ext.Panel);

PalletPanel = function(){
  PalletPanel.superclass.constructor.call(this, {
    region: 'west',
    split: true,
    title: "Rack",
    collapsed:false,
    collapsible:true,
    titleCollapse:true,
    animCollapse:true,
    width: 70,
    layout: {
      type:'vbox',
      padding:'5',
      align:'stretch'
    },
    defaults:{margins:'0 0 5 0'},
    items:[
      {
        xtype:'button',
        iconCls: 'icon-add',
        text: 'Add',
        handler: function(){
          mapPanel.addRack();
        }
      }
    ]
  });
}
Ext.extend(PalletPanel, Ext.Panel);

ResourceTreePanel = function(){
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
    var max = dataJson.racks.count;
    for(var i=0;i<max;i++){
      var nm = dataJson.racks.rows[i].id;
      var rack = createNode( nm, nm, false, false );
      var smax = dataJson.racks.rows[i].servers.count;
      for(var j=0;j<smax;j++){
        var snm = dataJson.racks.rows[i].servers.rows[j].id;
        rack.appendChild(createNode( nm+":"+snm, snm, true, false ));
      }
      root.appendChild(rack);
    }
  }
  this.drawTree = function(){
    drawTree();
  }

  ResourceTreePanel.superclass.constructor.call(this,{
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
console.debug('Server Add..');
console.debug(resourceTreePanel.getSelectionModel().selNode.id);
        }
      },
      { iconCls: 'icon-delete',
        handler:function(){
console.debug('Server Remove..');
         }
      },
      { iconCls: 'icon-edit',
        handler:function(){
console.debug('Server Edit..');
        }
      }
    ],
    root:root,
    listeners: {
      'click': function(node){
        console.debug(node.getPath());
//      console.dir(node);
//      console.debug(root.childNodes.length);
//        alert('id:' + node.id);
      }
    }
  });
}
Ext.extend(ResourceTreePanel, Ext.tree.TreePanel);

ResourcePropertyPanel = function(){
  ResourcePropertyPanel.superclass.constructor.call(this, {
    title: "Property",
    autoScroll: true,
    split: true,
    width: 150,
    bodyStyle:'padding:15px',
    html: ''
  });
}
Ext.extend(ResourcePropertyPanel, Ext.Panel);

MapPanel = function(){
  var grid_x = 20;
  var grid_y = 20;
  var map_url = Ext.BLANK_IMAGE_URL;
  var render_end = false;
  var rack_width = 20;
  var rack_high  = 15;
  var boxDraw=false;
  var mousex1=0;
  var mousex1=0;
  var mousex2=-1;
  var mousey2=-1;
  var dataMap = new Array();

  function init(){
    Ext.override(Ext.dd.DD, {
      onDrag : function(e){
        var x = Ext.get(this.getEl()).getX()-top.getX();
        var y = Ext.get(this.getEl()).getY()-top.getY();
//console.debug(x);
//console.debug(y);
      },
      endDrag: function(e) {
//      alert(Ext.get(this.getEl()).id);
        var top = Ext.get('rackSurface');
        var x = Ext.get(this.getEl()).getX()-top.getX();
        var y = Ext.get(this.getEl()).getY()-top.getY();
        var dist_x = Math.floor(x / grid_x)*grid_x;
        var dist_y = Math.floor(y / grid_y)*grid_y;
        if((x % grid_x) > (grid_x/2)){
          dist_x += grid_x;
        }
        if((y % grid_y) > (grid_y/2)){
          dist_y += grid_y;
        }
        Ext.get(this.getEl()).applyStyles({'background-color': 'green'}); 
        Ext.get(this.getEl()).setX(top.getX()+dist_x);
        Ext.get(this.getEl()).setY(top.getY()+dist_y);
      }
    });
    var top = Ext.get('canvas');
    top.addListener("mousedown",mousedownHandler);
    top.addListener("mouseup",mouseupHandler);
    top.addListener("mousemove",mousemoveHandler);
  }

  function getCanvas()
  {
    var canvas = document.getElementById("canvas");
    if(canvas.getContext){
      var ctx = canvas.getContext("2d");
      ctx.lineWidth = 1;
      return ctx;
    }
    return null;
  }

  function setScreenSize()
  {
    var canvas = document.getElementById("canvas");
    var map = document.getElementById('map');
    canvas.height = map.height;
    canvas.width = map.width;
  }

  function clearSelCanvas(ctx){
    var canvas = document.getElementById("canvas");
    ctx.clearRect(0,0,canvas.width,canvas.height);
  }

  function gridLine(ctx) {
    var map = document.getElementById('map');
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

  function mouseupHandler(e, target) { 
    var ctx = getCanvas();
    if(ctx != null){
      clearSelCanvas(ctx);
      gridLine(ctx);

//
// ここで範囲中にあるラックを選択状態にする
//
//

// 連想配列には for in

for (var i in dataMap) {
  console.debug(i);
  console.debug(dataMap[i]);
}

    }
    boxDraw=false;
    mousex2=-1;
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

  function  selectRack(e,target) {

    console.debug(target.id);
    console.debug(dataMap[target.id]);

    resourceTreePanel.selectPath("/root/"+dataMap[target.id]);

//   Ext.get(target.id).applyStyles({'background-color': 'yellow'});
// console.debug("CTRL");
// console.debug(e.browserEvent.ctrlKey);
// console.debug("SHIFT");
// console.debug(e.browserEvent.shiftKey);
  }

  this.setMapInfo = function(url,grid){
    map_url = url;
    grid_x  = grid;
    grid_y  = grid;
    if(render_end){
      this.changeMap();
    }
  }

  function drawRack(){
    if(render_end){
	  var max = dataJson.racks.count;
	  for(var i=0;i<max;i++){
	      var rtn = deployRack(dataJson.racks.rows[i].x,dataJson.racks.rows[i].y);
		  // ここで自動で付けられたIDとデータをマッピングする
	      dataMap[rtn] = dataJson.racks.rows[i].id;
	  }
	}
  }

  function changeMap(){
    var map = document.getElementById('map');
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

  this.changeMap = function(){
    changeMap();
  }
  this.drawRack = function(){
    drawRack();
  }

  var taskDrawMap = new Ext.util.DelayedTask(function(){
    changeMap();
  });
  var taskDrawRack = new Ext.util.DelayedTask(function(){
    drawRack();
    resourceTreePanel.drawTree();
  });

  var selectedRack = null;

  var myMenu = new Ext.menu.Menu({
    style: { overflow: 'visible' },
    items: [
      {text:'add server',
        handler: function(node,e){
          console.debug(selectedRack);
          selectedRack = null;
        }
      },
      {text:'delete rack',
        handler: function(node,e){
// console.debug(e.browserEvent);
          console.debug(selectedRack);
          selectedRack = null;
        }
      }
    ]
  });

  function deployRack(x,y){
    var myEl = new Ext.Element(document.createElement('div'));
    myEl.setWidth(rack_width-2);
    myEl.setHeight(rack_high-2);
    myEl.setStyle({ 'position':'absolute' });
    myEl.setStyle({ 'background-color':'red' });
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
// /rack-create?x=0;y=0
//  suucess（rack id）
//	/rack-list
//  dataJson.racks.rows.push[]
//  dataMap[rtn] = 
	// selectするRACKを管理
    var x = 20;
    var y = 20;
    var rtn = deployRack(x,y);
  }

  MapPanel.superclass.constructor.call(this, {
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
         if(dataJson != null){
           taskDrawRack.delay(100);
         }
         render_end = true;
      }
    },
    html: '<div style="position:absolute"><img id="map" src="'+Ext.BLANK_IMAGE_URL+'"></div><canvas id="canvas" style="position:absolute"></canvas><div id="rackSurface" style="position:absolute"></div>'
  });
}
Ext.extend(MapPanel, Ext.Panel);

