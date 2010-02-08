
ResourceEditorPanel = function(){

  var mtabPanel = new MapPanel("./images/map/1F-10.jpeg");
  var palletPanel = new PalletPanel(mtabPanel);

  var resourceTreePanel = new ResourceTreePanel();
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

  var store1 = new Ext.data.Store({
    proxy: new Ext.data.HttpProxy({
      url: '/map-list',
      method:'GET'
    }),
    listeners: {
      'load': function( temp , records, ope ){
        if(records.length > 0){
          combo.setValue(records[0].id);
        }
      }
    },
    reader: new Ext.data.JsonReader({
      totalProperty: "totalCount",
      root:'rows',
      fields:[
        { name:'id'    ,type:'string'},
        { name:'nm'    ,type:'string'},
        { name:'url'   ,type:'string'},
        { name:'grid'  ,type:'int'}
      ]
    })
  });
//  store.load();

  var store = new Ext.data.SimpleStore({
    fields : ["ID","nm","url","grid"],
    data : [
      ["1","1F-100","xxxx.jpg",20],
      ["2","2F-100","xxxx",20],
      ["3","3F-100","xxxx",20],
      ["4","3F-200","xxxx",20]
    ]
  });

  ResourceEditorPanel.superclass.constructor.call(this, {
    split: true,
    header: false,
    border: false,
    layout: 'border',
    items: [palletPanel,mtabPanel,editPanel],
    tbar: [{
      xtype: 'combo',
      editable: false,
      store: store,
      mode: 'local',
      width: 100,
      triggerAction: 'all',
      displayField: 'nm',
      value:'1',
      valueField: 'ID'
    }]
  });
}
Ext.extend(ResourceEditorPanel, Ext.Panel);

MAPTabPanel = function(posi,size){
  MAPTabPanel.superclass.constructor.call(this, {
    split: true,
    region: posi,
    width: size,
    activeTab: 0
  });
}
Ext.extend(MAPTabPanel, Ext.TabPanel);

PalletPanel = function(mapPanel){
  var mPanel = mapPanel;
  PalletPanel.superclass.constructor.call(this, {
    region: 'west',
    split: true,
    collapsed:false,
    collapsible:true,
    titleCollapse:true,
    animCollapse:true,
    width: 80,
    layout: {
      type:'vbox',
      padding:'5',
      align:'stretch'
    },
    defaults:{margins:'0 0 5 0'},
    items:[{
      xtype:'button',
      text: 'Add Rack',
      handler: function(){
        mPanel.addRack();
      }
    }]
  });
}
Ext.extend(PalletPanel, Ext.Panel);

ResourceTreePanel = function(){
  ResourceTreePanel.superclass.constructor.call(this,{
    split: true,
    title: 'Server',
    border: false,
    useArrows:true,
    width: 160,
    rootVisible: false,
    tbar : [
      { 
        iconCls: 'icon-add',
        handler:function(){
          alert('Add');
        }
      },
      { iconCls: 'icon-delete',
        handler:function(){
          alert('Remove');
         }
      },
      { iconCls: 'icon-edit',
        handler:function(){
          alert('Edit');
        }
      }
    ],
    root:{
      text:      '',
      draggable: false,
      id:        'root',
      expanded:  true,
      children:  [
        {
          id:       'child1',
          text:     'RACK-AAAA',
          expanded:  true,
          children:  [
            {
              id:       'menu01',
              text:     'Server0001',
              leaf:     true
            },
            {
              id:       'menu02',
              text:     'Server0002',
              leaf:     true
            }
          ]
        },
        {
          id:       'child2',
          text:     'RACK-BBBB',
          expanded:  true,
          children:  [
            {
              id:       'menu03',
              text:     'ServerAAAAA',
              leaf:     true
            }
          ]
        }
      ]
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
    html: 'XXXXXXXX'
  });
}
Ext.extend(ResourcePropertyPanel, Ext.Panel);

MapPanel = function(url){
  MapPanel.superclass.constructor.call(this, {
    region: 'center',
    autoScroll: true,
    split: true,
    layout: 'fit',
    listeners:{
      'afterrender': function(){
        init();
        setScreenSize();
        var ctx = getCanvas();
        if(ctx != null){
          gridLine(ctx);
        }
        var top = Ext.get('canvas');
        top.addListener("mousedown",mousedownHandler);
        top.addListener("mouseup",mouseupHandler);
        top.addListener("mousemove",mousemoveHandler);
      }
    },
    html: '<div style="position:absolute"><img id="map" src="' + url + '"></div><canvas id="canvas" style="position:absolute"></canvas><div id="rackSurface" style="position:absolute"></div>'
  });

  var grid_x = 20;
  var grid_y = 20;
  var rack_width = 20;
  var rack_high  = 15;
  var boxDraw=false;
  var mousex1=0;
  var mousex1=0;
  var mousex2=-1;
  var mousey2=-1;

  function init(){
    Ext.override(Ext.dd.DD, {
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

  // select rack
  function  selectRack(e,target) {
//   Ext.get(target.id).applyStyles({'background-color': 'yellow'});
// console.debug("CTRL");
// console.debug(e.browserEvent.ctrlKey);
// console.debug("SHIFT");
// console.debug(e.browserEvent.shiftKey);
  }

  var myMenu = new Ext.menu.Menu({
    id: 'mainMenu',
    style: { overflow: 'visible' },
    items: [
      {text:'add server'},
      {text:'delete rack'}
    ]
  });

//
//  this.loadImage = function(url){
//    var map = document.getElementById('map');
//    map.src = url;
//  }
//

  this.addRack = function(){
    var myEl = new Ext.Element(document.createElement('div'));
    myEl.setWidth(rack_width-2);
    myEl.setHeight(rack_high-2);
    myEl.setStyle({ 'position':'absolute' });
    myEl.setStyle({ 'background-color':'red' });
    myEl.setStyle({ 'border-style':'solid' });
    myEl.setStyle({ 'border-color':'black' });
    myEl.setStyle({ 'border-width':'2px' });
    myEl.setLocation(0,0);
    myEl.on('contextmenu', function(e){
      myMenu.showAt(e.getXY());
    }, null, {stopEvent:true});
    myEl.addListener("click",selectRack);
// alert(myEl.id);	ここで自動で付けられたIDとデータをマッピングする
    Ext.get('rackSurface').appendChild(myEl.dom);
    new Ext.dd.DD(myEl, "group1");
  }
}
Ext.extend(MapPanel, Ext.Panel);

