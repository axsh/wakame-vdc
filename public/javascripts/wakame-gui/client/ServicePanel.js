// Global Resources
Ext.apply(WakameGUI, {
  Service:null
});

WakameGUI.Service = function(){
  var sm = new Ext.grid.RowSelectionModel({singleSelect:true});
  var store = new Ext.data.SimpleStore({
    fields: [
      { name: 'wmi-id' },
      { name: 'name' },
      { name: 'owner-id' },
      { name: 'visibility' },
      { name: 'architecture' }
    ],
    data:[
      [ 'WK-2009', 'Blog', 'O10001', 'public', 'i386'],
      [ 'WK-2011', 'SNS', 'O10001', 'public', 'i386']
    ]
  });

  var clmnModel = new Ext.grid.ColumnModel([
    new Ext.grid.RowNumberer(),
    { header: "WMI-ID", width: 100, dataIndex: 'wmi-id' },
    { header: "Name", width: 100, dataIndex: 'name' },
    { header: "Owner", width: 100, dataIndex: 'owner-id' },
    { header: "Visibility", width: 100, dataIndex: 'visibility' },
    { header: "Architecture", width: 100, dataIndex: 'architecture'  }
  ]);

  WakameGUI.Service.superclass.constructor.call(this, {
    title: 'Service',
    store: store,
    cm:clmnModel,
    sm:sm,
    width: 320,
    autoHeight: false,
    stripeRows: true,
    bbar: new Ext.PagingToolbar({
      pageSize: 1,
      store: store,
      displayInfo: true,
      displayMsg: 'Displaying data {0} - {1} of {2}',
      emptyMsg: "No data to display"
    }),
    tbar : [
      { text : 'Launch',handler:function(){}
      },
      { text : 'Delete',handler:function(){}
      }
    ]
  });
}
Ext.extend(WakameGUI.Service, Ext.grid.GridPanel);
