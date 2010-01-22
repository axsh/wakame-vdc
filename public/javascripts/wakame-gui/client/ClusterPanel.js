
ClusterPanel = function(){
  var clistPanel = new ClusterListPanel();
  var cctrlPanel = new ClusterCtrlPanel();
  ClusterPanel.superclass.constructor.call(this, {
    title: 'Cluster',
    width: 320,
    header: false,
    border: false,
    layout: 'border',
	items: [clistPanel,cctrlPanel]
  });
}
Ext.extend(ClusterPanel, Ext.Panel);

ClusterListPanel = function(){
  var sm = new Ext.grid.RowSelectionModel({singleSelect:true});
  var store = new Ext.data.SimpleStore({
    fields: [
      { name: 'cluster-id' },
      { name: 'name' },
      { name: 'state' },
      { name: 'public-dns' }
    ],
    data:[
      [ 'AA9999995', 'Blog', 'running',  'axsh1.com/sssss/']
    ]
  });
  var clmnModel = new Ext.grid.ColumnModel([
    new Ext.grid.RowNumberer(),
    { header: "Cluster ID", width: 100, dataIndex: 'cluster-id' },
    { header: "Name", width: 100, dataIndex: 'name' },
    { header: "State", width: 50, dataIndex: 'state' },
    { header: "Public DNS", width: 100, dataIndex: 'public-dns' }
  ]);

  ClusterListPanel.superclass.constructor.call(this, {
    region: 'center',
    store: store,
    cm:clmnModel,
    sm:sm,
    width: 320,
    split: true,
    autoHeight: false,
    stripeRows: true,
    bbar: new Ext.PagingToolbar({
      pageSize: 1,
      store: store,
      displayInfo: true,
      displayMsg: 'Displaying data {0} - {1} of {2}',
      emptyMsg: "No data to display"
    })
  });
}
Ext.extend(ClusterListPanel, Ext.grid.GridPanel);

ClusterCtrlPanel = function(){

  var sm = new Ext.grid.RowSelectionModel({singleSelect:true});
  var store = new Ext.data.SimpleStore({
    fields: [
      { name: 'app-name' },
      { name: 'state' },
      { name: 'now' },
      { name: 'future' },
      { name: 'setting' }
    ],
    data:[
      [ 'Apache', 'running', '2',  '2', ''],
      [ 'LB',     'running', '1',  '1', ''],
      [ 'MySQL',  'running', '1',  '1', '']
    ]
  });
  var clmnModel = new Ext.grid.ColumnModel([
    new Ext.grid.RowNumberer(),
    { header: "Application", width: 100, dataIndex: 'app-name' },
    { header: "state", width: 100, dataIndex: 'state' },
    { header: "Now", width: 50, dataIndex: 'now' },
    { header: "Future", width: 50, dataIndex: 'future' },
    { header: "Setting", width: 50, dataIndex: 'setting' }
  ]);

  ClusterCtrlPanel.superclass.constructor.call(this, {
    region: 'east',
    store: store,
    cm:clmnModel,
    sm:sm,
    width: 380,
    split: true,
    autoHeight: true,
    stripeRows: true,
    tbar : [
      { text : 'Reboot',handler:function(){}
      },
      { text : 'Terminate',handler:function(){}
      },
      { text : 'Backup',handler:function(){}
      },
      { text : 'Restore',handler:function(){}
      }
    ]
  });
}
Ext.extend(ClusterCtrlPanel, Ext.grid.GridPanel);

