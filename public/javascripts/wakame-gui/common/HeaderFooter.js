// Global Resources
Ext.apply(WakameGUI, {
  Header:null,
  Footer:null
});

WakameGUI.Header = function(headerTitle){

  function reqeustSuccess(response)
  {
    if (response.responseText !== undefined) { 
      Ext.getDom("WELCOME_MESSAGE").innerHTML = 'Welcome , ' + response.responseText;
    }
  }

  WakameGUI.Header.superclass.constructor.call(this,{
    region: "north", 
    height: 0,
    border: false,
    listeners: {
      'afterrender': function(node){
        Ext.Ajax.request({
	      url: '/user-name',
	      method: "GET",
          success: reqeustSuccess
	    });
      }
    },
    tbar : [
      { xtype: 'tbtext',
        style: 'color:#0000ff; font-size:14px;',
        text : headerTitle
      },'->','-',
      { xtype: 'tbtext',
        id: 'WELCOME_MESSAGE',
        text : ''
      },'-',
      { text : 'Help',handler:function(){ alert('Help'); }
      },'-',
      { text: 'Logout',
        handler:function(){ location.href = "/logout" }
      },'-'
    ]
  });
}
Ext.extend(WakameGUI.Header, Ext.Panel);

WakameGUI.Footer = function(){
  WakameGUI.Footer.superclass.constructor.call(this,{
    region: "south", 
    height: 0,
    border: false,
    tbar : [
      { xtype: 'tbtext',
        text : '2009-2010,axsh Co., Ltd. All right reserved.'
      }
    ]
  });
}
Ext.extend(WakameGUI.Footer, Ext.Panel);
