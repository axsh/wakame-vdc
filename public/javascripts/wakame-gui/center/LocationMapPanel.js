
LocationMapPanel = function(){
  var mPropertyPanel = new MAPPropertyPanel();
  var mtabPanel  = new MAPTabPanel('center',600);
  mtabPanel.add(new MAPViewPanel('1F-100',"./images/map/1F-10.jpeg"));
  mtabPanel.add(new MAPViewPanel('1F-101',"./images/map/1F-10.jpeg"));
  mtabPanel.add(new MAPViewPanel('2F-101',"./images/map/1F-10.jpeg"));
  mtabPanel.add(new MAPViewPanel('2F-200',"./images/map/1F-10.jpeg"));
  mtabPanel.add(new MAPViewPanel('3F-105',"./images/map/1F-10.jpeg"));
  mtabPanel.add(new MAPViewPanel('3F-200',"./images/map/1F-10.jpeg"));

  LocationMapPanel.superclass.constructor.call(this, {
    split: true,
    header: false,
    border: false,
    layout: 'border',
	items: [mtabPanel,mPropertyPanel],
    tbar : [
      { text : 'Add Map',
        handler:function(){
          var addmap = new AddMapWindow();
		  addmap.show();
        }
      },
      { text : 'Remove',handler:function(){
          alert('Remove');
         }
      },
      { text : 'Edit',handler:function(){
          alert('Edit');
        }
      }
    ]
  });
}
Ext.extend(LocationMapPanel, Ext.Panel);

MAPPropertyPanel = function(){
  MAPPropertyPanel.superclass.constructor.call(this, {
    region: 'east',
    title: "Property",
    split: true,
    width: 150,
    collapsed:false,
    collapsible:true,
    titleCollapse:true,
    animCollapse:true,
    bodyStyle:'padding:15px',
    html: 'Memo:xxxx'
  });
}
Ext.extend(MAPPropertyPanel, Ext.Panel);

AddMapWindow = function(){
  var form = new Ext.form.FormPanel({
    width: 400,
    frame:true,
    bodyStyle:'padding:5px 5px 0',
    fileUpload: true,
    items: [{
      fieldLabel: 'Map-Name',
      xtype: 'textfield',
      name: 'account-id',
      anchor: '100%'
    }, {
      fieldLabel: 'Map-File',
      xtype: 'textfield',
      inputType: 'file',
      width: 200,
      name: 'map-file',
      anchor: '100%'
    }, {
      fieldLabel: 'Memo',
      xtype: 'textarea',
      name: 'form_textfield',
      anchor: '100%'
    }]
  });
  AddMapWindow.superclass.constructor.call(this, {
    iconCls: 'icon-panel',
    height: 220,
    width: 400,
	layout:'fit',
    title: 'Add Map',
	items: [form],
	buttons: [{
      text:'Save',
      handler: function(){
        form.getForm().submit({
          url: '/map_upload',
          waitMsg: 'Uploading...',
          method: 'POST',
          scope: this,
          success: function(form, action) {
            alert('Success !');
	        this.close();
          },
          failure: function(form, action) {
            alert('Upload file failure.');
	        this.close();
          }
        });
      },
      scope:this
    },{
	  text: 'Close',
	  handler: function(){
        this.close();
      },
      scope:this
    }]
  });
}
Ext.extend(AddMapWindow, Ext.Window);
