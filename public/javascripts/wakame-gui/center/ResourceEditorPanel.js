
ResourceEditorPanel = function(){
  var mtabPanel  = new MAPTabPanel('center',600);
  mtabPanel.add(new MAPViewPanel('1F-100'));
  mtabPanel.add(new MAPViewPanel('1F-101'));
  mtabPanel.add(new MAPViewPanel('2F-101'));
  mtabPanel.add(new MAPViewPanel('2F-200'));
  mtabPanel.add(new MAPViewPanel('3F-105'));
  mtabPanel.add(new MAPViewPanel('3F-200'));

  var palletPanel = new PalletPanel();
  var resourceTreePanel = new ResourceTreePanel();
  var resourcePropertyPanel = new ResourcePropertyPanel();
  var editPanel = new Ext.Panel({
    region: 'east',
    width: 150,
    defaults     : { flex : 1 }, //auto stretch
    layoutConfig : { align : 'stretch' },
    split: true,
	layout: 'vbox',
    items : [palletPanel,resourceTreePanel,resourcePropertyPanel]
  });

  ResourceEditorPanel.superclass.constructor.call(this, {
    split: true,
    header: false,
    border: false,
    layout: 'border',
    items: [mtabPanel,editPanel]
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

PalletPanel = function(){
  PalletPanel.superclass.constructor.call(this, {
    split: true,
    width: 150,
    layout: {
      type:'vbox',
      padding:'5',
      align:'stretch'
    },
    defaults:{margins:'0 0 5 0'},
    items:[{
      xtype:'button',
      text: 'Add Rack'
    },{
      xtype:'button',
      text: 'Remove Rack'
    },{
      xtype:'button',
      text: 'Edit Rack'
    },{
      xtype:'button',
      text: 'Select Range'
    },{
      xtype:'button',
      text: 'Lock'
    },{
      xtype:'button',
      text: 'UnLock'
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

MAPViewPanel = function(name){
  MAPViewPanel.superclass.constructor.call(this, {
    region: 'center',
    title: name,
    autoScroll: true,
    split: true,
    layout: 'fit',
    html: '<img src="1F-10.jpeg">'
//  bodyStyle: "background-image:url(1F-10.jpeg); background-repeat: no-repeat; background-attachment: fixed;"
  });
}
Ext.extend(MAPViewPanel, Ext.Panel);

