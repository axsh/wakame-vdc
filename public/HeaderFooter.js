
NorthPanel = function(headerTitle){
  NorthPanel.superclass.constructor.call(this,{
    region: "north", 
    height: 0,
    border: false,
    tbar : [
      { xtype: 'tbtext',
        style: 'color:#0000ff; font-size:14px;',
        text : headerTitle
      },'->','-',
      { xtype: 'tbtext',
        text : 'Welcome , xxxxx'
      },'-',
      { text : 'Help',handler:function(){ alert('Help'); }
      },'-',
      { text: 'Logout',
        handler:function(){ alert('Logout'); }
      },'-'
    ]
  });
}
Ext.extend(NorthPanel, Ext.Panel);


SouthPanel = function(){
  SouthPanel.superclass.constructor.call(this,{
    region: "south", 
    height: 0,
    border: false,
    tbar : [
      { xtype: 'tbtext',
        text : '2009,axsh Co., Ltd. All right reserved.'
      }
    ]
  });
}
Ext.extend(SouthPanel, Ext.Panel);
