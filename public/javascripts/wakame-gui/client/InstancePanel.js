
InstancePanel = function(){
  var sm = new Ext.grid.RowSelectionModel({singleSelect:true});
  var store = new Ext.data.Store({
    proxy: new Ext.data.HttpProxy({
      url: '/instance-list',
      method:'GET'
    }),
    reader: new Ext.data.JsonReader({
      totalProperty: "totalCount",
      root:'rows',
      fields:[
        { name:'id' ,type:'string'},
        { name:'od' ,type:'string'},
        { name:'wd' ,type:'string'},
        { name:'st' ,type:'string'},
//      { name:'pub-dns' ,type:'string'},
//      { name:'pri-dns' ,type:'string'},
        { name:'ip' ,type:'string'},
        { name:'tp' ,type:'string'}
//      { name:'sv' ,type:'string'}
      ]
    })
  });

  function statusChange(val){
    if(val == "pending"){
      return '<span style="color:#FF9000;">' + val + '</span>';
    } else if(val == "running"){
      return '<span style="color:#4FFF00;">' + val + '</span>';
    } else {
      return '<span style="color:gray;">' + val + '</span>';
    }
    return val;
  }

  var clmnModel = new Ext.grid.ColumnModel([
    new Ext.grid.RowNumberer(),
    { header: "Instance ID" ,width: 100, dataIndex: 'id'},
    { header: "Owner"       ,width: 100, dataIndex: 'od'},
    { header: "WMI ID"      ,width: 100, dataIndex: 'wd'},
    { header: "State"       ,width: 80,  dataIndex: 'st' , renderer: statusChange},
//  { header: "Public DNS"  ,width: 100, dataIndex: 'pub-dns'},
//  { header: "Private DNS" ,width: 100, dataIndex: 'pri-dns'},
    { header: "Private IP"  ,width: 100, dataIndex: 'ip'},
    { header: "type"        ,width: 50,  dataIndex: 'tp'}
//  { header: "Service"     ,width: 100, dataIndex: 'sv'}
  ]);

  this.refresh = function(){
    store.reload();
  }

  function reqeustSuccess()
  {
    store.reload();
  }

  function  reqeustfailure()
  {
    alert('Request failure.');
  }

  var toolbar= new Ext.PagingToolbar({
      pageSize: 50,
      store: store,
      displayInfo: true,
      displayMsg: 'Displaying data {0} - {1} of {2}',
      emptyMsg: "No data to display"
  });

  InstancePanel.superclass.constructor.call(this, {
    title: 'Instance',
    store: store,
    cm:clmnModel,
    sm:sm,
    width: 320,
    autoHeight: false,
    stripeRows: true,
    bbar: toolbar,
    tbar : [
      { text : 'Reboot',handler:function(){
		  if(sm.getCount() <= 0)
            return;
          Ext.Ajax.request({
	        url: '/instance-reboot',
	        method: "POST", 
            params : 'id=' + sm.getSelected().id
	      }); 
        }
      },
      { text : 'Terminate',handler:function(){
		  if(sm.getCount() <= 0)
            return;
          Ext.Ajax.request({
	        url: '/instance-terminate',
	        method: "POST", 
            params : 'id=' + sm.getSelected().id,
            success: reqeustSuccess,
            failure: reqeustfailure
	      });
        }
      },
      { text : 'Save',handler:function(){
		  if(sm.getCount() <= 0)
            return;
          Ext.Ajax.request({
	        url: '/instance-save',
	        method: "POST", 
            params : 'id=' + sm.getSelected().id
	      }); 
        }
      }
    ]
  });
  store.load({params: {start: 0, limit: 50}});		// limit = page size
}
Ext.extend(InstancePanel, Ext.grid.GridPanel);

