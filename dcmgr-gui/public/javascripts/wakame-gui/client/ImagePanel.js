/*-
 * Copyright (c) 2010 axsh co., LTD.
 * All rights reserved.
 *
 * Author: Takahisa Kamiya
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 */

// Global Resources
Ext.apply(WakameGUI, {
  Image:null
});

WakameGUI.Image = function(){
  var instancePanel = null;
  var sm = new Ext.grid.RowSelectionModel({singleSelect:true}); 
  var store = new Ext.data.Store({
    proxy: new Ext.data.HttpProxy({
      url: '/image-list',
      method:'GET'
    }),
    reader: new Ext.data.JsonReader({
      totalProperty: "totalCount",
      root:'rows',
      fields:[
        { name:'id' ,type:'string'},
        { name:'nm' ,type:'string'},
        { name:'od' ,type:'string'},
        { name:'vy' ,type:'string'},
        { name:'ac' ,type:'string'}
      ]
    })
  });
  var clmnModel = new Ext.grid.ColumnModel([
    new Ext.grid.RowNumberer(),
    { header: "WMI-ID",       width: 100, dataIndex: 'id' },
    { header: "Manifest",     width: 200, dataIndex: 'nm' },
    { header: "Owner",        width: 100, dataIndex: 'od' },
    { header: "Visibility",   width: 100, dataIndex: 'vy' },
    { header: "Architecture", width: 100, dataIndex: 'ac' }
  ]);

  toolbar = new Ext.PagingToolbar({
      pageSize: 50,
      store: store,
      displayInfo: true,
      displayMsg: 'Displaying data {0} - {1} of {2}',
      emptyMsg: "No data to display"
  });

  var upPanel = null;

  this.refresh = function(){
    store.reload();
  }

  this.setUpPanel = function(obj){
    upPanel = obj;
  }

  this.setInstancePanel = function(obj){
    instancePanel = obj;
  }

  WakameGUI.Image.superclass.constructor.call(this, {
    title: 'Image',
    store: store,
    cm:clmnModel,
    sm:sm,
    width: 320,
    autoHeight: false,
    stripeRows: true,
    bbar: toolbar,
    tbar : [
      { text : 'Launch',handler:function(){
		  var temp = sm.getCount();
		  if(temp > 0){
            var aid  =  upPanel.getSelectedAccount();
            var data = sm.getSelected();
			var launchWin = new LaunchWindow(data,aid);
			launchWin.show();
          }
        }
      },
      { text : 'Delete',handler:function(){}
      }
    ]
  });
  store.reload();

  Ext.TaskMgr.start({
    run: function(){
      if(WakameGUI.activePanel == 1){
        store.reload();
      }
    },
    interval: 60000
  });

  LaunchWindow = function(launchData,account_id){
    var form = new Ext.form.FormPanel({
      labelWidth: 50,
      width: 330,
      baseCls: 'x-plain',
      items: [
      {
      fieldLabel: 'WMI-ID',
      xtype: 'displayfield',
      value: launchData.get('id'),
      anchor: '100%'
      }
      ,{
      fieldLabel: 'Name',
      xtype: 'displayfield',
      value: launchData.get('nm'),
      anchor: '100%'
      },
      {
      xtype: 'hidden',
      id: 'wd',
      value: launchData.get('id'),
      }
      ,{
      xtype: 'hidden',
      id: 'id',
      value: account_id,
      }
      ,{
      fieldLabel: 'TYPE',
      xtype: 'combo',
      editable: false,
      id: 'tp',
      width: 80,
      forceSelection:true,
      mode: 'local',
      store: new Ext.data.ArrayStore({
        id: 1,
        fields: [
         'myId',
          'displayText'
        ],
        data: [[1,'small'],[2, 'large']]
      }),
      triggerAction: 'all',
	  value:'1',
      valueField: 'myId',
      displayField: 'displayText'
      }]
    });
    LaunchWindow.superclass.constructor.call(this, {
      iconCls: 'icon-panel',
      collapsible:true,
      titleCollapse:true,
      height: 170,
      width: 350,
	  layout:'fit',
	  closeAction:'hide',
      title: 'Launch',
	  modal: true,
	  plain: true,
      defaults:{bodyStyle:'padding:15px'},
	  items: [form],
	  buttons: [{
	    text:'Launch',
        handler: function(){
          form.getForm().submit({
            url: '/instance-create',
            waitMsg: 'creating...',
            method: 'POST',
            scope: this,
            success: this.submitSuccess,
            failure: this.submitFailure
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
  Ext.extend(LaunchWindow, Ext.Window , {
    submitSuccess: function(form, action){
      this.close();
      instancePanel.refresh();
    },
    submitFailure: function(form, action){
      alert('Create failure.');
      this.close();
    }
  });
}
Ext.extend(WakameGUI.Image, Ext.grid.GridPanel);
