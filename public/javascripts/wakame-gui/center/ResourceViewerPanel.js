// Global Resources
Ext.apply(WakameGUI, {
  querySelect:0,
  ChangeQuery : function(md){
    if(WakameGUI.querySelect != md){
      WakameGUI.querySelect = md;
    }
  },
  ResourceViewer:null,
  ServerQuery:null,
  ServerList:null,
  MAPTab:null
});

WakameGUI.ResourceViewer = function(){
  var serverquery = new WakameGUI.ServerQuery();
  var serverlist  = new WakameGUI.ServerList();
  var mtabPanel   = new WakameGUI.MAPTab('east',250);

  mtabPanel.add(new WakameGUI.MAPView('1F-100',"/images/map/1F-10.jpeg"));
  mtabPanel.add(new WakameGUI.MAPView('1F-101',"/images/map/1F-10.jpeg"));

  WakameGUI.ResourceViewer.superclass.constructor.call(this, {
    split: true,
    header: false,
    border: false,
    layout: 'border',
	items: [serverquery,serverlist,mtabPanel]
  });
}
Ext.extend(WakameGUI.ResourceViewer, Ext.Panel);


WakameGUI.ServerQuery = function(){
  WakameGUI.ServerQuery.superclass.constructor.call(this, {
    height:70,
    region: 'north',
    frame : true,
    bodyStyle:'padding:5px',
    items: [{
      layout:'column',
      items:[{
        columnWidth:.8,
        layout: 'form',
        items: [{
            fieldLabel: 'Keyword',
            xtype: 'textfield',
            name: 'account-id',
            anchor: '100%'
        }]
      },{
        labelWidth: 5, 
        columnWidth:.2,
        layout: 'form',
        items: [{
          xtype: 'combo',
          editable: false,
          anchor: '100%',
          forceSelection:true,
          mode: 'local',
          store: new Ext.data.ArrayStore({
            id: 1,
            fields: [
              'myId',
              'displayText'
            ],
            data: [[1,'include'],[2, 'exact']]
          }),
          triggerAction: 'all',
		  value:'1',
          valueField: 'myId',
          displayField: 'displayText'
        }]
      }]
    }],
	buttons: [{
	  text:'Search',
	  handler: function(){
        alert('Search');
	  },
	  scope:this
	}]
  });
}
Ext.extend(WakameGUI.ServerQuery, Ext.form.FormPanel);

WakameGUI.ServerList = function(){
  var rackPanel = new RackPanel();
  var hwPanel   = new HWPanel();
  var hvcPanel  = new HVCPanel();
  var hvaPanel  = new HVAPanel();
  var vmPanel   = new VMPanel();
  WakameGUI.ServerList.superclass.constructor.call(this, {
    split: true,
    region: 'center',
    activeTab: 0, 
    items: [rackPanel,hwPanel,hvcPanel,hvaPanel,vmPanel]
  });
}
Ext.extend(WakameGUI.ServerList, Ext.TabPanel);

RackPanel = function(){
  var sm = new Ext.grid.RowSelectionModel({singleSelect:false});
  var store = new Ext.data.SimpleStore({
    fields: [
      { name: 'rack-id'   },
      { name: 'rack-name' },
      { name: 'location'  },
      { name: 'memo'      }
    ],
    data:[ 
      [ '1001', 'AA001', '1F-1001', 'for test'],
      [ '1002', 'AA002', '1F-1001', 'for test'],
      [ '1003', 'AA003', '1F-1001', 'for test'],
      [ '1004', 'AA004', '1F-1001', 'for test'],
      [ '1005', 'AB001', '2F-1001', 'for test'],
      [ '1006', 'AB002', '2F-1001', 'for test']
    ]
  });

  var clmnModel = new Ext.grid.ColumnModel([
    new Ext.grid.RowNumberer(),
    { header: "Rack-ID"  , width: 100, dataIndex: 'rack-id'   },
    { header: "Rack-Name", width: 150, dataIndex: 'rack-name' },
    { header: "location" , width: 150, dataIndex: 'location'  },
    { header: "Memo"     , width: 150, dataIndex: 'memo'      }
  ]);

  RackPanel.superclass.constructor.call(this, {
    title: "Rack",
    listeners: {activate:function() { WakameGUI.ChangeQuery(2);} },
    store: store,
    cm:clmnModel,
    sm:sm,
    width: 320,
    autoHeight: false,
    stripeRows: true,
    loadMask: {msg: 'Loading...'},
    bbar: new Ext.PagingToolbar({
      pageSize: 50,
      store: store,
      displayInfo: true,
      displayMsg: 'Displaying data {0} - {1} of {2}',
      emptyMsg: "No data to display"
    })
  });
}
Ext.extend(RackPanel, Ext.grid.GridPanel);

HWPanel = function(){
  var sm = new Ext.grid.RowSelectionModel({singleSelect:false});
  var store = new Ext.data.Store({
    proxy: new Ext.data.HttpProxy({
      url: '/physicalhost-list',
      method:'GET'
    }),
    reader: new Ext.data.JsonReader({
      totalProperty: "totalCount",
      root:'rows',
      fields:[
        { name:'id' ,type:'string'     },
        { name:'cpus' ,type:'string'   },
        { name:'mhz' ,type:'string'    },
        { name:'memory' ,type:'string' },
        { name:'htype' ,type:'string'  },
        { name:'hvcadr' ,type:'string' },
        { name:'ip' ,type:'string'     },
        { name:'rack-nm' ,type:'string'},
        { name:'pool' ,type:'string'   },
        { name:'location' ,type:'string'},
        { name:'memo' ,type:'string'    }
      ]
    })
  });

  var clmnModel = new Ext.grid.ColumnModel([
    new Ext.grid.RowNumberer(),
    { header: "Server-ID"  , width: 100, dataIndex: 'id'       },
    { header: "CPUS"       , width: 100, dataIndex: 'cpus'     },
    { header: "Hz"         , width: 100, dataIndex: 'mhz'      },
    { header: "Memory"     , width: 100, dataIndex: 'memory'   },
    { header: "Type"       , width: 100, dataIndex: 'htype'    },
    { header: "HVC-address", width: 100, dataIndex: 'hvcadr'   },
    { header: "IP-address" , width: 100, dataIndex: 'ip'       },
    { header: "Rack-Name"  , width: 150, dataIndex: 'rack-nm'  },
    { header: "Pool"       , width: 150, dataIndex: 'pool'     },
    { header: "Location"   , width: 150, dataIndex: 'location' },
    { header: "Memo"       , width: 150, dataIndex: 'memo'     }
  ]);

  HWPanel.superclass.constructor.call(this, {
    title: "Server",
    listeners: {activate:function() { WakameGUI.ChangeQuery(3);} },
    store: store,
    cm:clmnModel,
    sm:sm,
    width: 320,
    autoHeight: false,
    stripeRows: true,
    loadMask: {msg: 'Loading...'},
    bbar: new Ext.PagingToolbar({
      pageSize: 50,
      store: store,
      displayInfo: true,
      displayMsg: 'Displaying data {0} - {1} of {2}',
      emptyMsg: "No data to display"
    })
  });
  store.load({params: {start: 0, limit: 50}});		// limit = page size

}
Ext.extend(HWPanel, Ext.grid.GridPanel);

HVCPanel = function(){
  var sm = new Ext.grid.RowSelectionModel({singleSelect:false});
  var store = new Ext.data.SimpleStore({
    fields: [
      { name: 'a' }, { name: 'b' },{ name: 'c' }, { name: 'd' },
      { name: 'e' }, { name: 'f' },{ name: 'g' }, { name: 'h' }
    ],
    data:[
      [ 'H-1001', 'run', 'Core2Duo 2.4GHz', 3000 , '192.168.10.10', 'x86_64', '2F-22-001-00' , 'for test'],
      [ 'H-1002', 'stoped', 'Celeron 2GHz',    3000 , '192.168.11.10', 'i386'  , '1F-02-001-00' , 'Destroy'],
      [ 'H-2001', 'stoped', 'Core2Duo 1.6GHz', 3000 , '192.168.12.10', 'x86_64', '2F-22-002-00' , 'for test'],
      [ 'H-2003', 'run', 'Celeron 1GHz' ,   2000 , '192.168.13.10', 'i386'  , '2F-10-004-00' , 'for test'],
      [ 'H-3001', 'stoped', 'Celeron 1GHz',    2000 , '192.168.14.10', 'i386'  , '2F-10-005-00' , 'for test']
    ]
  });

  var clmnModel = new Ext.grid.ColumnModel([
    new Ext.grid.RowNumberer(),
    { header: "HVC-ID", width: 100, dataIndex: 'a' },
    { header: "State", width: 60, dataIndex: 'b' },
    { header: "Manifest", width: 150, dataIndex: 'c' },
    { header: "Memory", width: 70, dataIndex: 'd' },
    { header: "Private IP", width: 80, dataIndex: 'e' },
    { header: "Architecture", width: 100, dataIndex: 'f' },
    { header: "Location", width: 120, dataIndex: 'g' },
    { header: "Memo", width: 120, dataIndex: 'h' }
  ]);

  var addWin = null;

  // private member
  function getSelectedHVCID()
  {
    var temp = sm.getCount();
    if(temp == 0){
      return null;
    }
    else{
      return sm.getSelected().get('a');
    }
  }

  HVCPanel.superclass.constructor.call(this, {
    store: store,
    cm:clmnModel,
    sm:sm,
    title: "HVC",
    width: 320,
    autoHeight: false,
    stripeRows: true,
    loadMask: {msg: 'Loading...'},
    listeners: {activate:function() { WakameGUI.ChangeQuery(0);} },
    bbar: new Ext.PagingToolbar({
      pageSize: 50,
      store: store,
      displayInfo: true,
      displayMsg: 'Displaying data {0} - {1} of {2}',
      emptyMsg: "No data to display"
    })
  });
}
Ext.extend(HVCPanel, Ext.grid.GridPanel);

HVAPanel = function(){
  var sm = new Ext.grid.RowSelectionModel({singleSelect:false});
  var store = new Ext.data.SimpleStore({
    fields: [
      { name: 'a' },{ name: 'b' },{ name: 'c' },{ name: 'd' },
      { name: 'e' },{ name: 'f' },{ name: 'g' },
      { name: 'h' }
    ],
    data:[ 
      [ 'HA-1001', 'run', 'Core2Duo 2.4GHz', 3000 , '192.168.10.10', 'x86_64', '2F-22-001-01' , 'for test'],
      [ 'HA-1002', 'stoped', 'Celeron 2GHz',    3000 , '192.168.11.10', 'i386'  , '2F-22-001-02' , 'Destroy'],
      [ 'HA-1003', 'stoped', 'Core2Duo 1.6GHz', 3000 , '192.168.12.10', 'x86_64', '2F-22-001-03' , 'for test'],
      [ 'HA-1004', 'run', 'Celeron 1GHz' ,   2000 , '192.168.13.10', 'i386'  , '2F-22-001-04' , 'for test'],
      [ 'HA-1005', 'stoped', 'Celeron 1GHz',    2000 , '192.168.14.10', 'i386'  , '2F-22-001-05' , 'for test']
    ]
  });

  var clmnModel = new Ext.grid.ColumnModel([
    new Ext.grid.RowNumberer(),
    { header: "HVA-ID", width: 100, dataIndex: 'a' },
    { header: "State", width: 60, dataIndex: 'b' },
    { header: "Manifest", width: 150, dataIndex: 'c' },
    { header: "Memory", width: 70, dataIndex: 'd' },
    { header: "Private IP", width: 80, dataIndex: 'e' },
    { header: "Architecture", width: 100, dataIndex: 'f' },
    { header: "Location", width: 120, dataIndex: 'g' },
    { header: "Memo", width: 120, dataIndex: 'h' }
  ]);

  function getSelectedHVAID()
  {
    var temp = sm.getCount();
    if(temp == 0){
      return null;
    }
    else{
      return sm.getSelected().get('a');
    }
  }

  HVAPanel.superclass.constructor.call(this, {
    store: store,
    cm:clmnModel,
    sm:sm,
    title: "HVA",
    width: 320,
    autoHeight: false,
    stripeRows: true,
    loadMask: {msg: 'Loading...'},
    listeners: {activate:function() { WakameGUI.ChangeQuery(1);} },
    bbar: new Ext.PagingToolbar({
      pageSize: 50,
      store: store,
      displayInfo: true,
      displayMsg: 'Displaying data {0} - {1} of {2}',
      emptyMsg: "No data to display"
    })
  });
}
Ext.extend(HVAPanel, Ext.grid.GridPanel);

VMPanel = function(){
  var sm = new Ext.grid.RowSelectionModel({singleSelect:false});
  var store = new Ext.data.Store({
    proxy: new Ext.data.HttpProxy({
      url: '/instance-detail-list',
      method:'GET'
    }),
    reader: new Ext.data.JsonReader({
      totalProperty: "totalCount",
      root:'rows',
      fields:[
        { name:'id' ,type:'string'},
        { name:'sd' ,type:'string'},
        { name:'ad' ,type:'string'},
        { name:'ud' ,type:'string'},
        { name:'wd' ,type:'string'},
        { name:'st' ,type:'string'},
        { name:'ip' ,type:'string'},
        { name:'tp' ,type:'string'},
        { name:'sv' ,type:'string'}
      ]
    })
  });
  var clmnModel = new Ext.grid.ColumnModel([
    new Ext.grid.RowNumberer(),
    { header: "Instance-ID" , width: 100, dataIndex: 'id' },
    { header: "Server-ID"   , width: 120, dataIndex: 'sd' },
    { header: "Account-ID"  , width: 120, dataIndex: 'ad' },
    { header: "User-ID"     , width: 120, dataIndex: 'ud' },
    { header: "WMI-ID"      , width: 120, dataIndex: 'wd' },
    { header: "State"       , width: 120, dataIndex: 'st' },
    { header: "Type"        , width: 120, dataIndex: 'tp' },
    { header: "Service"     , width: 120, dataIndex: 'sv' }
  ]);

  VMPanel.superclass.constructor.call(this, {
    title: "Instance",
    store: store,
    cm:clmnModel,
    sm:sm,
    width: 320,
    autoHeight: false,
    stripeRows: true,
    listeners: {activate:function() { WakameGUI.ChangeQuery(4);} },
    loadMask: {msg: 'Loading...'},
    bbar: new Ext.PagingToolbar({
      pageSize: 50,
      store: store,
      displayInfo: true,
      displayMsg: 'Displaying data {0} - {1} of {2}',
      emptyMsg: "No data to display"
    })
  });
  store.load({params: {start: 0, limit: 50}});		// limit = page size
}
Ext.extend(VMPanel, Ext.grid.GridPanel);

WakameGUI.MAPTab = function(posi,size){
  WakameGUI.MAPTab.superclass.constructor.call(this, {
    split: true,
    region: posi,
    width: size,
    activeTab: 0
  });
}
Ext.extend(WakameGUI.MAPTab, Ext.TabPanel);

